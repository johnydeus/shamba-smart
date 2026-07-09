// Shamba Smart — gemini-proxy
//
// Secure proxy for Google Gemini IMAGE CLASSIFICATION (disease / pest /
// nutrient / weed). Mirrors claude-proxy's secret-handling + JWT gating so the
// GEMINI_API_KEY never ships in the APK. Claude stays for explanations only.
//
// PHASE 1: this function exists and is deployable, but the app does NOT call it
// yet. It is tested in isolation.
//
// Auth: the caller must be an authenticated Supabase user. We validate the JWT
// with a direct GoTrue fetch (no esm.sh SDK import) — the SDK + getUser()
// combo caused a BOOT_ERROR on another function in this project.
//
// Secret required (set in the Supabase dashboard, never in code):
//   GEMINI_API_KEY

const GEMINI_BASE = 'https://generativelanguage.googleapis.com/v1beta/models'
const TIMEOUT_MS = 20_000

// modelTier -> Gemini model id. Flash-Lite is the cheap default; Flash is the
// escalation for hard cases. Change here if Google revises model ids.
const MODEL_BY_TIER: Record<string, string> = {
  'flash-lite': 'gemini-2.5-flash-lite',
  'flash': 'gemini-2.5-flash',
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })

function buildPrompt(
  cropType: string,
  problemType: string,
  allowedLabels: string[],
): string {
  // OPEN detection whenever no closed list is supplied — identify the real
  // species from the model's own knowledge, same honesty rule (no inventing;
  // "Unknown" if unsure). This covers pests/weeds AND diseases on crops with
  // no bundled taxonomy (e.g. coffee/cashew varieties). Any call WITH labels
  // stays LOCKED to that list.
  const identificationRule = (allowedLabels.length === 0)
    ? `OPEN IDENTIFICATION — identify the actual ${problemType || 'disease'} in the image by
its real, known species or common name (English), using your own knowledge of
Tanzanian agriculture. You are NOT restricted to a fixed list. RULES: only
return a real, established ${problemType} name that affects a crop GROWN IN
TANZANIA / East Africa — NEVER invent one. If the plant is not a Tanzanian
agricultural crop (e.g. an ornamental, a wild/non-crop plant, or an exotic
species not grown in Tanzania), or you cannot identify it with reasonable
confidence, set "top_prediction" to "Unknown" and "needs_human_confirmation"
to true.`
    : `TAXONOMY LOCK — you may ONLY choose "top_prediction" and any
"alternative_predictions[].label" from this exact allowed list:
${allowedLabels.length ? allowedLabels.map((l) => `- ${l}`).join('\n') : '(no labels provided)'}

If the image does not clearly match ANY label in the list, you MUST set
"top_prediction" to "Unknown" and "needs_human_confirmation" to true. NEVER
invent a disease/pest/weed name that is not in the list.`

  return `You are an agricultural image classifier for Tanzanian crops.
Crop: ${cropType || 'unknown'}
Problem type to assess: ${problemType || 'disease'}

The image may show ANY part of the plant — leaf, pod, cob/ear, fruit, grain,
stem, branch, flower, tuber or root. Diagnose the ${problemType || 'disease'}
from whichever part is shown; do NOT assume it is a leaf, and use symptoms on
that specific part (spots, rot, lesions, discoloration, wilting, galls, etc.).

${identificationRule}

Assess image quality (blurry, too dark, too far, subject not centered, fine).
Set "needs_flash_escalation" to true if the image is hard/ambiguous and a
stronger model might help. Always write "farmer_safe_message" and
"recommended_next_action" in simple Swahili.

Respond with ONLY a single JSON object (no prose, no markdown fences) matching
EXACTLY this schema and key order:
{
  "model_used": "",
  "crop": "",
  "problem_type": "",
  "top_prediction": "",
  "confidence": 0.0,
  "alternative_predictions": [{"label": "", "confidence": 0.0}],
  "symptoms_seen": [""],
  "image_quality": "",
  "needs_flash_escalation": false,
  "needs_human_confirmation": true,
  "farmer_safe_message": "",
  "recommended_next_action": ""
}`
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405)

  // ── Auth: validate the caller's JWT against GoTrue ──
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

  // ── Secret ──
  const geminiKey = Deno.env.get('GEMINI_API_KEY')
  if (!geminiKey) return json({ error: 'Gemini API key not configured' }, 500)

  // ── Inputs ──
  let body: any
  try {
    body = await req.json()
  } catch {
    return json({ error: 'Invalid JSON body' }, 400)
  }
  const imageBase64 = body?.imageBase64 as string | undefined
  const cropType = (body?.cropType ?? '').toString()
  const problemType = (body?.problemType ?? 'disease').toString()
  const allowedLabels: string[] = Array.isArray(body?.allowedLabels)
    ? body.allowedLabels.map((l: unknown) => String(l))
    : []
  const tier = (body?.modelTier ?? 'flash-lite').toString()

  if (!imageBase64) return json({ error: 'imageBase64 is required' }, 400)

  const model = MODEL_BY_TIER[tier] ?? MODEL_BY_TIER['flash-lite']
  const mime = (body?.mimeType ?? 'image/jpeg').toString()

  // ── Call Gemini (JSON mode, deterministic) ──
  const url = `${GEMINI_BASE}/${model}:generateContent?key=${geminiKey}`
  const payload = {
    contents: [
      {
        parts: [
          { text: buildPrompt(cropType, problemType, allowedLabels) },
          { inline_data: { mime_type: mime, data: imageBase64 } },
        ],
      },
    ],
    generationConfig: {
      temperature: 0,
      responseMimeType: 'application/json',
    },
  }

  let geminiData: any
  try {
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(TIMEOUT_MS),
    })
    if (!res.ok) {
      const errText = await res.text()
      return json({ error: `Gemini error ${res.status}: ${errText.slice(0, 300)}` }, 502)
    }
    geminiData = await res.json()
  } catch (e) {
    return json({ error: `Gemini request failed: ${e instanceof Error ? e.message : e}` }, 502)
  }

  // ── Extract + parse the model's JSON answer ──
  const text: string | undefined =
    geminiData?.candidates?.[0]?.content?.parts?.[0]?.text
  if (!text) return json({ error: 'Gemini returned no content' }, 502)

  let parsed: any
  try {
    // Strip any accidental markdown fences before parsing.
    const clean = text.replace(/```json/gi, '').replace(/```/g, '').trim()
    parsed = JSON.parse(clean)
  } catch {
    return json({ error: 'Gemini returned non-JSON', raw: text.slice(0, 500) }, 502)
  }

  // Stamp the actual model used (don't trust the model to fill it).
  parsed.model_used = model
  return json(parsed)
})
