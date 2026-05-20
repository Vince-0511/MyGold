import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'subscription_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    subscriptionService.addListener(_onSubscriptionChanged);
    _loadAd();
  }

  void _onSubscriptionChanged() {
    if (subscriptionService.isAdFree) {
      if (mounted) {
        setState(() => _isLoaded = false);
        _bannerAd?.dispose();
        _bannerAd = null;
      }
    }
  }

  void _loadAd() {
    if (subscriptionService.isAdFree) return;

    _bannerAd = BannerAd(
      adUnitId: kReleaseMode
          ? 'ca-app-pub-8958676039974787/6300978111' // Production banner ID — replace with your real one from AdMob
          : 'ca-app-pub-3940256099942544/6300978111', // Google test banner ID
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Banner ad failed to load: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    subscriptionService.removeListener(_onSubscriptionChanged);
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (subscriptionService.isAdFree) return const SizedBox.shrink();

    if (_isLoaded && _bannerAd != null) {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return const SizedBox.shrink();
  }
}
