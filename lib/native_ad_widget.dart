import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'subscription_service.dart';

class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({super.key});

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    subscriptionService.addListener(_onSubscriptionChanged);
    _loadAd();
  }

  void _onSubscriptionChanged() {
    // If user unlocks premium, immediately wipe out the ad structure cleanly
    if (subscriptionService.isAdFree) {
      if (mounted) {
        setState(() {
          _isAdLoaded = false;
        });
        _nativeAd?.dispose();
        _nativeAd = null;
      }
    }
  }

  void _loadAd() {
    // 🎯 Edge-Case Security Check: Avoid making requests if user is already pro
    if (subscriptionService.isAdFree) {
      if (mounted) {
        setState(() {
          _isAdLoaded = false;
        });
      }
      return;
    }

    _nativeAd = NativeAd(
      // 🎯 Change this block to check for kReleaseMode instead
      adUnitId: kReleaseMode
          ? 'ca-app-pub-8958676039974787/7863548301' // 🚀 Force Production ID in true Release Mode
          : 'ca-app-pub-3940256099942544/2247696110', // 🛠️ Fall back to Test ID for Debug & Profile Modes
      // 🚨 NOTE: Make sure 'listTile' factory is registered in your MainActivity.kt/java!
      factoryId: 'listTile',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Ad failed to load: $error');
        },
      ),
    );

    _nativeAd!.load();
  }

  @override
  void dispose() {
    subscriptionService.removeListener(_onSubscriptionChanged);
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 If user is Pro, explicitly return an empty space regardless of load states
    if (subscriptionService.isAdFree) {
      return const SizedBox.shrink();
    }

    if (_isAdLoaded && _nativeAd != null) {
      return Container(
        alignment: Alignment.center,
        // ➡️ Rigid physical boundary protection to avoid crashing complex Column layouts
        height: 110.0,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        padding: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: const Color(
            0xFF1E293B,
          ), // Updated to match your Dashboard's slate theme instead of stark white!
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AdWidget(ad: _nativeAd!),
      );
    }

    return const SizedBox.shrink();
  }
}
