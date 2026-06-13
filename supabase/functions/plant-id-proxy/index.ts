import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

const ENDPOINTS: Record<string, string> = {
  crop_health: 'https://crop.kindwise.com/api/v1/identification',
  plant_id: 'https://api.plant.id/v3/identification',
}

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

  // Expect: { service: 'crop_health' | 'plant_id', ...body }
  const { service, ...apiBody } = await req.json()

  const endpoint = ENDPOINTS[service]
  if (!endpoint) {
    return new Response(JSON.stringify({ error: `Unknown service: ${service}` }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  const apiKey = service === 'crop_health'
    ? Deno.env.get('CROP_HEALTH_KEY')
    : Deno.env.get('PLANT_ID_KEY')

  if (!apiKey) {
    return new Response(JSON.stringify({ error: `${service} key not configured` }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  const apiRes = await fetch(endpoint, {
    method: 'POST',
    headers: {
      'Api-Key': apiKey,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(apiBody),
  })

  const data = await apiRes.json()
  return new Response(JSON.stringify(data), {
    status: apiRes.status,
    headers: { 'Content-Type': 'application/json' },
  })
})
