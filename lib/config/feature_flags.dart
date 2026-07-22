/// Central, app-wide feature flags.
///
/// Keep behavior toggles here (separate from API-key availability in
/// `api_keys.dart`). Flip a flag in this one place to enable/disable a path.
class FeatureFlags {
  FeatureFlags._();

  /// USE_GEMINI_SCAN — master switch for the Gemini scan path.
  ///
  /// When true, crop image CLASSIFICATION routes to Gemini (gemini-proxy)
  /// instead of Claude/Plant.id. Claude remains for explanations only.
  /// Mkulima AI stays primary and offline-first regardless.
  ///
  /// Default FALSE: the app behaves exactly as today (Mkulima AI ->
  /// Claude/Plant.id). Nothing reads this flag yet — wiring happens in a
  /// later phase.
  ///
  /// (A remote override — e.g. a Supabase row — can be layered on later if
  /// needed; a compile-time const is deliberate for now to avoid over-engineering.)
  static const bool useGeminiScan = true;

  /// USE_MKULIMA_LOCAL — master switch for the on-device Mkulima AI (MobileNet)
  /// classifier in the live scan pipeline.
  ///
  /// Default FALSE (disabled, not deleted): Mkulima AI was producing confidently
  /// WRONG results on real photos (e.g. misidentifying diseased coffee cherries
  /// as "Healthy Cashew" at 76% confidence) and its green-pixel gate was
  /// rejecting good photos before Gemini ever saw them. A confidently wrong
  /// result is more dangerous to a farmer than an honest "unknown", so disease
  /// scans now go straight to Gemini — no local inference, no green-pixel gate.
  ///
  /// NOTE: with useMkulimaLocal=false AND useGeminiScan=true (both current
  /// defaults), Gemini is the ONLY classifier and there is NO offline scanning
  /// path. This is intentional until a retrained Mkulima AI (using the
  /// diagnoses data now being captured) is available to restore as a local
  /// fallback. All Mkulima code/model/assets remain in the repo untouched —
  /// flip this back to true to restore the on-device path in one line.
  static const bool useMkulimaLocal = false;
}
