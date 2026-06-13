import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

const ISDA_BASE = 'https://api.isda-africa.com/v1/soil'

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

  const isdaToken = Deno.env.get('ISDASOIL_TOKEN')
  if (!isdaToken) {
    return new Response(JSON.stringify({ error: 'iSDA token not configured' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  // Expect: { lat, lon, property, depth }
  const { lat, lon, property, depth } = await req.json()

  const url = new URL(ISDA_BASE)
  url.searchParams.set('lat', lat)
  url.searchParams.set('lon', lon)
  url.searchParams.set('property', property)
  url.searchParams.set('depth', depth)

  const isdaRes = await fetch(url.toString(), {
    headers: { Authorization: `Bearer ${isdaToken}` },
  })

  const data = await isdaRes.json()
  return new Response(JSON.stringify(data), {
    status: isdaRes.status,
    headers: { 'Content-Type': 'application/json' },
  })
})
