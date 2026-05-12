/// Single source of truth for per-app identity values that live in Dart.
///
/// When forking the template for a new app, edit the values in this file
/// and follow `docs/CUSTOMISATION.md` for the surfaces that cannot be
/// centralised here (bundle IDs, launcher icons, font binaries).
///
/// Conventions (mirrors [AppColors]):
///   - `class` + private ctor + `static const` fields
///   - no state, no DI, importable anywhere
class AppConfig {
  AppConfig._();

  // ─── Identity ─────────────────────────────────────────────────────
  /// Display name shown in the MaterialApp title, drawer header,
  /// and About page.
  static const String appName = 'PriceCompare';

  /// One-line description shown on the About page.
  static const String appDescription = '複数商品の単価を即時計算・比較するアプリ';

  /// Short tagline rendered under the app name in the drawer.
  static const String appTagline = '価格比較 & 履歴管理';

  // ─── Home page copy ───────────────────────────────────────────────
  static const String homeSubtitle = '価格比較 & 履歴管理';
  static const String homeCardTitle = 'PriceCompare';

  // ─── Typography ───────────────────────────────────────────────────
  /// Must exactly match the `family:` entry in `pubspec.yaml`'s fonts
  /// section. Both values are the contract between Flutter's font loader
  /// and the declared assets — drift causes silent fallback to system fonts.
  static const String fontFamily = 'NotoSansJP';

  // ─── Design system attribution (About + LicenseRegistry) ──────────
  static const String designSystemLabel = 'DADS v2.10.3';
  static const String designSystemName =
      'Digital Agency Design System (DADS)';
  static const String designSystemUrl = 'https://design.digital.go.jp/';
  static const String designSystemLicense = 'CC BY 4.0';
}
