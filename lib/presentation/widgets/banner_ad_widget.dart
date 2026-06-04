import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/ads/ad_config.dart';

/// A self-contained, lifecycle-managed adaptive banner ad widget.
///
/// - Loads its own [BannerAd] on mount and disposes it on unmount.
/// - Uses adaptive banner sizing for the device screen width.
/// - Shows [SizedBox.shrink()] while loading or on failure — zero layout cost.
/// - Wrapped in [RepaintBoundary] to isolate ad rendering from the host screen.
/// - Safe to use in any screen EXCEPT: auth, payment, emergency, video, AI assistant.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd == null) {
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    // Compute adaptive banner height for the device screen width
    final adWidth = MediaQuery.sizeOf(context).width.truncate();
    final adSize = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(adWidth)
        ?? AdSize.banner; // Fallback to standard 320×50 banner

    _bannerAd = BannerAd(
      adUnitId: AdConfig.bannerId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() => _isLoaded = true);
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
          // Silent fail — no error UI shown to user
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    if (!_isLoaded || ad == null) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}

