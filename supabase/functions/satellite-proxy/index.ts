import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

const EOSDA_BASE = 'https://api.agromonitoring.com/agro/1.0'
const PLANET_BASE = 'https://api.planet.com/data/v1'

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  const authHeader = req.headers.get('Authorization')
  if (!authHeader?.startsWith('Bearer ')) {
    return new Response(JSON.stringify({ error: 'Missing authorization' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    { global: { headers: { Authorization: authHeader } } },
  )
  const { data: { user }, error: authError } = await supabase.auth.getUser()
  if (authError || !user) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  // Expect: { service: 'eosda'|'planet', method: 'GET'|'POST', path: '/...', query?: {}, body?: {} }
  const { service, method, path, query, body } = await req.json()

  if (service === 'eosda') {
    const eosdaKey = Deno.env.get('EOSDA_API_KEY')
    if (!eosdaKey) {
      return new Response(JSON.stringify({ error: 'EOSDA key not configured' }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const url = new URL(`${EOSDA_BASE}${path}`)
    url.searchParams.set('apikey', eosdaKey)
    if (query) {
      for (const [k, v] of Object.entries(query)) {
        url.searchParams.set(k, String(v))
      }
    }

    const eosdaRes = await fetch(url.toString(), {
      method: method ?? 'GET',
      headers: { 'Content-Type': 'application/json' },
      body: body ? JSON.stringify(body) : undefined,
    })

    const data = await eosdaRes.json()
    return new Response(JSON.stringify(data), {
      status: eosdaRes.status,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  if (service === 'planet') {
    const planetKey = Deno.env.get('PLANET_API_KEY')
    if (!planetKey) {
      return new Response(JSON.stringify({ error: 'Planet key not configured' }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const url = new URL(`${PLANET_BASE}${path}`)
    if (query) {
      for (const [k, v] of Object.entries(query)) {
        url.searchParams.set(k, String(v))
      }
    }

    const planetRes = await fetch(url.toString(), {
      method: method ?? 'GET',
      headers: {
        'Authorization': `api-key ${planetKey}`,
        'Content-Type': 'application/json',
      },
      body: body ? JSON.stringify(body) : undefined,
    })

    const data = await planetRes.json()
    return new Response(JSON.stringify(data), {
      status: planetRes.status,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  return new Response(JSON.stringify({ error: `Unknown service: ${service}` }), {
    status: 400,
    headers: { 'Content-Type': 'application/json' },
  })
})
