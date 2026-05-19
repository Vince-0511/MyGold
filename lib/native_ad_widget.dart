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

  // 🎯 2. YOU ARE MISSING THIS EXACT FUNCTION BLOCK BELOW!
  // Copy and paste this directly inside the class body:
  void _onSubscriptionChanged() {
    if (subscriptionService.isAdFree) {
      if (mounted) {
        setState(() {
          _isAdLoaded = false;
        });
        _nativeAd?.dispose();
      }
    }
  }

  void _loadAd() {
    if (subscriptionService.isAdFree) {
      setState(() {
        _isAdLoaded = false;
      });
      return;
    }
    _nativeAd = NativeAd(
      adUnitId: kDebugMode
          ? 'ca-app-pub-3940256099942544/2247696110' // Safe Test ID for Emulator
          : 'ca-app-pub-8958676039974787/7863548301',
      factoryId: 'listTile',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print('Ad failed to load: $error');
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
    if (_isAdLoaded && _nativeAd != null) {
      return Container(
        alignment: Alignment.center,
        // ➡️ Force a structural layout boundary for the native engine
        height: 110.0,
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        padding: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
