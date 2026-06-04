import 'package:flutter/foundation.dart';

/// Centralized Ad Unit IDs for Google AdMob.
///
/// All ad types use Google's official test IDs in debug/profile builds.
/// Replace the `_realXxx` constants with your production Ad Unit IDs from
/// the AdMob console before releasing to the Play Store / App Store.
///
/// Test IDs source: https://developers.google.com/admob/flutter/test-ads
class AdConfig {
  const AdConfig._();

  // ─── Environment switch ────────────────────────────────────────────────────
  /// Set this to `true` to force Google test ads in all build modes (including release).
  /// Set to `false` when preparing the final release to the App Store / Play Store.
  static const bool _forceTestIds = true;

  static bool get _useTestIds => _forceTestIds || kDebugMode || kProfileMode;

  // ─── Real production IDs (replace before release) ─────────────────────────
  static const String _realBannerId      = 'ca-app-pub-9926926816557444/6429192459';
  static const String _realInterstitialId = 'ca-app-pub-9926926816557444/1554619815';
  static const String _realRewardedId    = 'ca-app-pub-9926926816557444/5056401037';

  // ─── Google official test IDs ──────────────────────────────────────────────
  /// Official Google AdMob test banner ID (adaptive banner).
  static const String _testBannerId = 'ca-app-pub-3940256099942544/9214589741';

  /// Official Google AdMob test interstitial ID.
  static const String _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';

  /// Official Google AdMob test rewarded ID.
  static const String _testRewardedId = 'ca-app-pub-3940256099942544/5224354917';

  // ─── Public API ────────────────────────────────────────────────────────────
  static String get bannerId =>
      _useTestIds ? _testBannerId : _realBannerId;

  static String get interstitialId =>
      _useTestIds ? _testInterstitialId : _realInterstitialId;

  static String get rewardedId =>
      _useTestIds ? _testRewardedId : _realRewardedId;

  // ─── AdMob Application ID (required in AndroidManifest.xml) ──────────────
  /// Google's test app ID.
  static const String testAppId = 'ca-app-pub-3940256099942544~3347511713';

  /// Your production AdMob app ID.
  static const String productionAppId = 'ca-app-pub-9926926816557444~9334861319';
}
