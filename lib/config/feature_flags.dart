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
}
