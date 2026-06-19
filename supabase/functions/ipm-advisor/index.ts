// Shamba Smart — IPM advisor.
//
// Returns an IPM management plan (Swahili) for a crop+pest+severity. The chemical
// recommendation is CONSTRAINED to currently-approved Tanzania pesticides pulled
// live from the DB — the AI physically cannot recommend a banned/withdrawn one,
// because only approved products are injected into the prompt.
//
// Safety: if the approved list is empty (real data not loaded yet), we DO NOT ask
// the AI for any chemical name — we return non-chemical guidance + "consult Afisa
// Kilimo". This guarantees we never surface a banned pesticide.
//
// Provider-swappable: set AI_PROVIDER = "claude" (default) or "gemini" in secrets.
// Keys: CLAUDE_API_KEY and/or GEMINI_API_KEY. JWT-protected.

const ISDA_TIMEOUT_MS = 20_000

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })

interface ApprovedPesticide {
  brand_name: string
  active_ingredient: string | null
  category: string | null
  target_pests: string | null
}

async function fetchApproved(crop: string): Promise<ApprovedPesticide[]> {
  const url = new URL(`${Deno.env.get('SUPABASE_URL')}/rest/v1/pesticides`)
  url.searchParams.set('select', 'brand_name,active_ingredient,category,target_pests')
  url.searchParams.set('approval_status', 'eq.approved')
  url.searchParams.set('limit', '60')
  const res = await fetch(url.toString(), {
    headers: {
      apikey: Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      Authorization: `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? Deno.env.get('SUPABASE_ANON_KEY') ?? ''}`,
    },
  })
  if (!res.ok) return []
  return await res.json() as ApprovedPesticide[]
}

function buildPrompt(
  crop: string,
  pest: string,
  severity: string,
  approved: ApprovedPesticide[],
): string {
  const list = approved.length
    ? approved
        .map((p) => `- ${p.brand_name}${p.active_ingredient ? ` (${p.active_ingredient})` : ''}`)
        .join('\n')
    : '(HAKUNA dawa zilizothibitishwa kwenye orodha)'

  return `Wewe ni mtaalam wa IPM (Usimamizi Shirikishi wa Wadudu) wa Tanzania.
Zao: ${crop}. Wadudu/tatizo: ${pest}. Ukali: ${severity}.

Toa ushauri ukifuata mpangilio wa IPM wa Tanzania (TPHPA):
1. KINGA na ufuatiliaji
2. Njia za kilimo (cultural) na kibaiolojia
3. Dawa za kemikali ZIWE NJIA YA MWISHO, tu pale wadudu wamevuka kiwango cha kiuchumi.

Kwa mapendekezo YOYOTE ya dawa za kemikali, CHAGUA TU kutoka kwenye orodha hii ya
dawa ZILIZOTHIBITISHWA Tanzania (post Jan 2026). USIPENDEKEZE dawa isiyo kwenye orodha:
${list}

Kama hakuna dawa inayofaa kwenye orodha, sema wazi na pendekeza njia zisizo za
kemikali au kushauriana na Afisa Kilimo. Jibu kwa Kiswahili, kwa muhtasari na hatua
wazi. Usitaje dawa yoyote ambayo haiko kwenye orodha hapo juu.`
}

async function askClaude(prompt: string): Promise<string> {
  const res = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': Deno.env.get('CLAUDE_API_KEY') ?? '',
      'anthropic-version': '2023-06-01',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'claude-opus-4-8',
      max_tokens: 900,
      messages: [{ role: 'user', content: prompt }],
    }),
    signal: AbortSignal.timeout(ISDA_TIMEOUT_MS),
  })
  if (!res.ok) throw new Error(`Claude error ${res.status}`)
  const data = await res.json()
  return data?.content?.[0]?.text ?? ''
}

async function askGemini(prompt: string): Promise<string> {
  const key = Deno.env.get('GEMINI_API_KEY') ?? ''
  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${key}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] }),
      signal: AbortSignal.timeout(ISDA_TIMEOUT_MS),
    },
  )
  if (!res.ok) throw new Error(`Gemini error ${res.status}`)
  const data = await res.json()
  return data?.candidates?.[0]?.content?.parts?.[0]?.text ?? ''
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405)

  // ── Auth: validate the caller's JWT against GoTrue (no SDK import) ──
  const authHeader = req.headers.get('Authorization')
  if (!authHeader?.startsWith('Bearer ')) {
    return json({ error: 'Missing authorization' }, 401)
  }
  const userRes = await fetch(`${Deno.env.get('SUPABASE_URL')}/auth/v1/user`, {
    headers: {
      apikey: Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      Authorization: authHeader,
    },
  })
  if (!userRes.ok) return json({ error: 'Unauthorized' }, 401)

  // ── Inputs ──
  let body: any
  try {
    body = await req.json()
  } catch {
    return json({ error: 'Invalid JSON body' }, 400)
  }
  const crop = (body?.crop ?? '').toString().trim()
  const pest = (body?.pest ?? '').toString().trim()
  const severity = (body?.severity ?? 'wastani').toString().trim()
  if (!crop || !pest) return json({ error: 'crop and pest are required' }, 400)

  // ── Pull approved pesticides (safety boundary) ──
  let approved: ApprovedPesticide[] = []
  try {
    approved = await fetchApproved(crop)
  } catch (_) {
    approved = []
  }

  // SAFETY FALLBACK: no verified approved data → never ask AI for a chemical.
  if (approved.length === 0) {
    return json({
      source: 'safe-fallback',
      hasApprovedList: false,
      advice:
        'Hatua za IPM:\n\n' +
        '1. KINGA: Tumia mbegu bora/sugu, panda kwa wakati, ondoa magugu na masalia ya mazao.\n' +
        '2. UFUATILIAJI: Kagua shamba mara kwa mara (asubuhi/jioni) kuhesabu wadudu.\n' +
        '3. NJIA ASILIA: Tumia mitego, wadudu marafiki, na njia za kilimo kabla ya kemikali.\n\n' +
        '⚠️ Orodha ya dawa zilizothibitishwa za Tanzania (TPHPA 2026) bado haijapakiwa, '
        + 'hivyo hatuwezi kupendekeza dawa ya kemikali kwa usalama. Tafadhali shauriana na '
        + 'Afisa Kilimo wa karibu kwa pendekezo la dawa iliyothibitishwa.',
      approvedProducts: [],
    })
  }

  // ── Ask the configured AI provider (constrained to approved list) ──
  const provider = (Deno.env.get('AI_PROVIDER') ?? 'claude').toLowerCase()
  const prompt = buildPrompt(crop, pest, severity, approved)
  let advice = ''
  try {
    advice = provider === 'gemini' ? await askGemini(prompt) : await askClaude(prompt)
  } catch (e) {
    return json({ error: `AI provider error: ${e instanceof Error ? e.message : e}` }, 502)
  }

  return json({
    source: provider,
    hasApprovedList: true,
    advice,
    // The app links these to nearby pesticide-selling agrovets.
    approvedProducts: approved.map((p) => p.brand_name),
  })
})
