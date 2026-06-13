import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

const CLAUDE_URL = 'https://api.anthropic.com/v1/messages'

Deno.serve(async (req) => {
  // Only accept POST
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  // Verify caller is an authenticated Supabase user
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

  const claudeKey = Deno.env.get('CLAUDE_API_KEY')
  if (!claudeKey) {
    return new Response(JSON.stringify({ error: 'Claude API key not configured' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  // Forward body transparently to Claude
  const body = await req.json()
  const claudeRes = await fetch(CLAUDE_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': claudeKey,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify(body),
  })

  const data = await claudeRes.json()
  return new Response(JSON.stringify(data), {
    status: claudeRes.status,
    headers: { 'Content-Type': 'application/json' },
  })
})
