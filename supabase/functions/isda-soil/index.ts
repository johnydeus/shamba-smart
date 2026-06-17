// Shamba Smart — iSDAsoil proxy with automatic login.
//
// Why this exists: iSDAsoil access tokens expire after 60 minutes. Storing a
// static token as a secret means it dies for everyone an hour later. This
// function instead stores the USERNAME + PASSWORD as secrets, logs in to get a
// fresh token on demand, caches it in memory for the warm instance's life, and
// fetches all requested soil properties in a SINGLE call.
//
// Secrets required (set via `supabase secrets set`):
//   ISDA_USERNAME, ISDA_PASSWORD
//
// Auth: caller must be an authenticated Supabase user (JWT validated) so the
// iSDAsoil quota can't be abused by randoms.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

const ISDA_BASE = 'https://api.isda-africa.com'
const TOKEN_TTL_MS = 55 * 60 * 1000 // refresh a little before the 60-min expiry
const ISDA_TIMEOUT_MS = 12_000

// App-facing key  ->  iSDAsoil v2 property slug (note British "phosphorous").
const PROPERTY_MAP: Record<string, string> = {
  ph: 'ph',
  nitrogen_total: 'nitrogen_total',
  phosphorus_extractable: 'phosphorous_extractable',
  potassium_extractable: 'potassium_extractable',
  organic_carbon: 'carbon_organic',
  clay: 'clay_content',
  sand: 'sand_content',
  silt: 'silt_content',
}
const DEFAULT_PROPERTIES = Object.keys(PROPERTY_MAP)

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })

// In-memory token cache — survives while the function instance stays warm.
let cachedToken: string | null = null
let tokenExpiry = 0

async function getToken(): Promise<string> {
  if (cachedToken && Date.now() < tokenExpiry) return cachedToken

  const username = Deno.env.get('ISDA_USERNAME')
  const password = Deno.env.get('ISDA_PASSWORD')
  if (!username || !password) {
    throw new Error('iSDA credentials not configured')
  }

  const form = new URLSearchParams()
  form.set('username', username)
  form.set('password', password)

  const ctrl = new AbortController()
  const t = setTimeout(() => ctrl.abort(), ISDA_TIMEOUT_MS)
  try {
    const res = await fetch(`${ISDA_BASE}/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: form,
      signal: ctrl.signal,
    })
    if (!res.ok) throw new Error(`iSDA login failed (${res.status})`)
    const body = await res.json()
    const token = body.access_token as string | undefined
    if (!token) throw new Error('iSDA login returned no access_token')
    cachedToken = token
    tokenExpiry = Date.now() + TOKEN_TTL_MS
    return token
  } finally {
    clearTimeout(t)
  }
}

// Tolerant extractor for the v2 response shape:
//   { property: { ph: [ { value: { value: 6.1 }, depth: {...} } ] } }
function extractValue(payload: any, slug: string): number | null {
  const entry = payload?.property?.[slug]
  if (!Array.isArray(entry) || entry.length === 0) return null
  const v = entry[0]?.value
  const num = typeof v === 'object' ? v?.value : v
  return typeof num === 'number' ? num : null
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405)

  // ── Validate the caller is an authenticated Supabase user ──
  const authHeader = req.headers.get('Authorization')
  if (!authHeader?.startsWith('Bearer ')) {
    return json({ error: 'Missing authorization' }, 401)
  }
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    { global: { headers: { Authorization: authHeader } } },
  )
  const { data: { user }, error: authError } = await supabase.auth.getUser()
  if (authError || !user) return json({ error: 'Unauthorized' }, 401)

  // ── Inputs ──
  let payload: any
  try {
    payload = await req.json()
  } catch {
    return json({ error: 'Invalid JSON body' }, 400)
  }
  const lat = payload?.lat
  const lon = payload?.lon
  if (lat == null || lon == null) {
    return json({ error: 'lat and lon are required' }, 400)
  }
  const depth: string = payload?.depth ?? '0-20'
  const requested: string[] = Array.isArray(payload?.properties) && payload.properties.length
    ? payload.properties
    : DEFAULT_PROPERTIES

  // ── Fetch all properties in one iSDA call ──
  let token: string
  try {
    token = await getToken()
  } catch (e) {
    return json({ error: `iSDA login error: ${e instanceof Error ? e.message : e}` }, 502)
  }

  const url = new URL(`${ISDA_BASE}/isdasoil/v2/soilproperty`)
  url.searchParams.set('lat', String(lat))
  url.searchParams.set('lon', String(lon))
  url.searchParams.set('depth', depth)
  for (const key of requested) {
    const slug = PROPERTY_MAP[key] ?? key
    url.searchParams.append('property', slug)
  }

  const ctrl = new AbortController()
  const timer = setTimeout(() => ctrl.abort(), ISDA_TIMEOUT_MS)
  let isdaJson: any
  try {
    let res = await fetch(url.toString(), {
      headers: { Authorization: `Bearer ${token}` },
      signal: ctrl.signal,
    })
    // Token may have expired mid-life — refresh once and retry.
    if (res.status === 401) {
      cachedToken = null
      token = await getToken()
      res = await fetch(url.toString(), {
        headers: { Authorization: `Bearer ${token}` },
        signal: ctrl.signal,
      })
    }
    if (!res.ok) {
      return json({ error: `iSDA data error (${res.status})` }, 502)
    }
    isdaJson = await res.json()
  } catch (e) {
    return json({ error: `iSDA request failed: ${e instanceof Error ? e.message : e}` }, 502)
  } finally {
    clearTimeout(timer)
  }

  // ── Normalise to the keys the app expects ──
  const data: Record<string, number> = {}
  for (const key of requested) {
    const slug = PROPERTY_MAP[key] ?? key
    const value = extractValue(isdaJson, slug)
    if (value != null) data[key] = value
  }

  if (Object.keys(data).length === 0) {
    return json({ error: 'No soil properties returned for this location' }, 404)
  }

  return json({ source: 'isda', depth, lat, lon, data })
})
