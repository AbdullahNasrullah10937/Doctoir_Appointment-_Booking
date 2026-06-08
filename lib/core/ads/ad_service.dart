import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';
import '../logging/logging_service.dart';

/// Centralized AdMob lifecycle manager for Qurexa.
///
/// Responsibilities:
///   - SDK initialization with GDPR UMP consent handling
///   - Preloading and caching interstitial + rewarded ads
///   - Enforcing per-type cooldown timers to prevent ad spam
///   - Graceful no-op fallback on all failure states
///
/// Usage:
///   final adService = AdService();
///   await adService.initialize();
///   await adService.showInterstitial(onDone: () { /* navigate */ });
///   await adService.showRewarded(onEarnReward: () { /* unlock feature */ });
class AdService {
  // ─── Cooldown guard ────────────────────────────────────────────────────────
  /// Minimum gap between consecutive interstitial shows (anti-spam).
  static const Duration _interstitialCooldown = Duration(seconds: 30);
  DateTime? _lastInterstitialShown;

  // ─── Ad instances ──────────────────────────────────────────────────────────
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool _interstitialLoading = false;
  bool _rewardedLoading = false;

  // ─── Initialization ────────────────────────────────────────────────────────

  /// Initializes the AdMob SDK and requests user consent via Google UMP.
  /// Must be called once at app startup, before any ad is loaded or shown.
  Future<void> initialize() async {
    try {
      // ── GDPR/CCPA: Request consent information update ──────────────────────
      // In google_mobile_ads 5.x, requestConsentInfoUpdate returns void and
      // uses success/failure callbacks rather than a Future.
      final params = ConsentRequestParameters();
      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          // Consent info updated — show form if required by user's jurisdiction
          if (await ConsentInformation.instance.isConsentFormAvailable()) {
            await ConsentForm.loadAndShowConsentFormIfRequired((_) {
              LoggingService.info('Consent form dismissed — initializing MobileAds.');
              _initMobileAds();
            });
          } else {
            _initMobileAds();
          }
        },
        (FormError error) {
          LoggingService.warning('Consent info update failed: ${error.message}');
          _initMobileAds();
        },
      );
    } catch (e) {
      LoggingService.warning('Initialization error (non-fatal): $e', error: e);
      _initMobileAds();
    }
  }

  Future<void> _initMobileAds() async {
    try {
      await MobileAds.instance.initialize();
      unawaited(preloadInterstitial());
      unawaited(preloadRewarded());
    } catch (e) {
      LoggingService.warning('MobileAds init error (non-fatal): $e', error: e);
    }
  }

  // ─── Interstitial ──────────────────────────────────────────────────────────

  /// Preloads an interstitial ad in the background.
  /// Call this after each interstitial show to keep the cache hot.
  Future<void> preloadInterstitial() async {
    if (_interstitialLoading) return;
    _interstitialLoading = true;

    await InterstitialAd.load(
      adUnitId: AdConfig.interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialLoading = false;
          LoggingService.info('Interstitial loaded.');
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _interstitialLoading = false;
          LoggingService.warning('Interstitial failed to load: ${error.message}');
        },
      ),
    );
  }

  /// Shows the preloaded interstitial ad if one is available and the cooldown
  /// has elapsed. Calls [onDone] in all cases (ad shown, skipped, or failed).
  ///
  /// Placement rule: Only call AFTER a natural user flow completion,
  /// never during authentication, payment, emergency, or active consultation.
  Future<void> showInterstitial({VoidCallback? onDone}) async {
    // ── Cooldown check ──────────────────────────────────────────────────────
    final now = DateTime.now();
    if (_lastInterstitialShown != null &&
        now.difference(_lastInterstitialShown!) < _interstitialCooldown) {
      LoggingService.info('Interstitial skipped — cooldown active.');
      onDone?.call();
      return;
    }

    // ── No ad loaded — graceful skip ────────────────────────────────────────
    if (_interstitialAd == null) {
      LoggingService.info('Interstitial skipped — not yet loaded.');
      onDone?.call();
      unawaited(preloadInterstitial()); // Trigger background reload
      return;
    }

    final ad = _interstitialAd!;
    _interstitialAd = null; // Consume the loaded ad

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        onDone?.call();
        unawaited(preloadInterstitial());
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        LoggingService.warning('Interstitial failed to show: ${error.message}');
        onDone?.call();
        unawaited(preloadInterstitial());
      },
    );

    _lastInterstitialShown = DateTime.now();
    await ad.show();
  }

  // ─── Rewarded ──────────────────────────────────────────────────────────────

  /// Preloads a rewarded ad in the background.
  Future<void> preloadRewarded() async {
    if (_rewardedLoading) return;
    _rewardedLoading = true;

    await RewardedAd.load(
      adUnitId: AdConfig.rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedLoading = false;
          LoggingService.info('Rewarded ad loaded.');
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _rewardedLoading = false;
          LoggingService.warning('Rewarded ad failed to load: ${error.message}');
        },
      ),
    );
  }

  /// Shows the rewarded ad if available.
  ///
  /// [onEarnReward] is called ONLY when the user completes the ad and earns
  /// the reward. It is never called if the user skips or the ad fails.
  ///
  /// [onDone] is always called regardless of outcome.
  Future<void> showRewarded({
    required VoidCallback onEarnReward,
    VoidCallback? onDone,
  }) async {
    if (_rewardedAd == null) {
      LoggingService.info('Rewarded ad skipped — not yet loaded.');
      onDone?.call();
      unawaited(preloadRewarded());
      return;
    }

    final ad = _rewardedAd!;
    _rewardedAd = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        onDone?.call();
        unawaited(preloadRewarded());
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        LoggingService.warning('Rewarded ad failed to show: ${error.message}');
        onDone?.call();
        unawaited(preloadRewarded());
      },
    );

    await ad.show(
      onUserEarnedReward: (_, reward) {
        LoggingService.info('Reward earned: ${reward.type} × ${reward.amount}');
        onEarnReward();
      },
    );
  }

  // ─── Disposal ──────────────────────────────────────────────────────────────

  /// Releases all loaded ad instances. Call from app root dispose().
  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _interstitialAd = null;
    _rewardedAd = null;
  }
}
