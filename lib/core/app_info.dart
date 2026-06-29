/// App-wide constants. Update [shareLink] when the real download URL is ready.
class AppInfo {
  /// Shown/stored with feedback. Bump alongside pubspec version.
  static const String version = '1.0.0+18';

  /// Placeholder download link — replace with the real Play Store / site URL.
  static const String shareLink = 'https://shambasmart.app';

  /// Message used by the "Mwalike Rafiki" share sheet.
  static String get inviteMessage =>
      'Jiunge na Shamba Smart — daktari wa shamba lako! 🌱\n'
      'Pata uchunguzi wa magonjwa ya mazao, ushauri wa kilimo, na soko — '
      'yote kwa Kiswahili.\nPakua hapa: $shareLink';
}
