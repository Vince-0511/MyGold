import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🎯 Persistent local backup

final subscriptionService = SubscriptionService();

class SubscriptionService extends ChangeNotifier {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  // 🎯 Tracks if the user has unlocked the ad-free experience
  bool _isAdFree = false;
  bool get isAdFree => _isAdFree;

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  // 🚨 PROFILE MODE FIX CONFIGURATION
  // Toggle this to TRUE to test the unlock flow smoothly in both Debug AND Profile Mode.
  // Toggle this to FALSE right before compiling your final deployment App Bundle for Google Play.
  final bool _isTestingSandbox = false;

  // Define your exact Product ID matching Google Play Console
  static const String adFreeProductId = 'remove_ads_subscription';

  void initialize() {
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      (purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      },
      onDone: () {
        _subscription.cancel();
      },
      onError: (error) {
        print("Purchase stream error: $error");
      },
    );

    // Pre-load product info and check past purchases on startup
    loadProducts();
    _loadLocalBackupStatus(); // Checks SharedPreferences so premium state saves on app close
  }

  /// Initial backup check so user stays pro locally during mock iterations
  Future<void> _loadLocalBackupStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('user_premium_status') == true) {
      _isAdFree = true;
      notifyListeners();
    }
  }

  // Fetch product price details dynamically from Google Play
  Future<void> loadProducts() async {
    if (_isTestingSandbox) return; // Skip online stores if simulating sandbox

    final bool available = await _inAppPurchase.isAvailable();
    if (!available) return;

    const Set<String> ids = {adFreeProductId};
    final ProductDetailsResponse response = await _inAppPurchase
        .queryProductDetails(ids);

    _products = response.productDetails;
    notifyListeners();
  }

  // Trigger the checkout loop engine
  Future<void> buySubscription() async {
    // 🎯 THE FIX: Works flawlessly in both Debug AND Profile mode run environments
    if (_isTestingSandbox) {
      print(
        "⚡ Sandbox Active: Simulating an immediate local payment success...",
      );
      await Future.delayed(
        const Duration(seconds: 2),
      ); // Artificial loading feel

      _isAdFree = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_premium_status', true);

      notifyListeners(); // 🚀 Force UI Screen to change states instantly!
      return;
    }

    if (_products.isEmpty) return;

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: _products.first,
    );
    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  // Check if user already owns the subscription when app launches
  Future<void> updatePastPurchases() async {
    if (_isTestingSandbox) {
      await Future.delayed(const Duration(milliseconds: 800));
      await _loadLocalBackupStatus();
      return;
    }
    await _inAppPurchase.restorePurchases();
  }

  void _listenToPurchaseUpdated(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Handle loading states
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        print("Purchase Error: ${purchaseDetails.error}");
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        if (purchaseDetails.productID == adFreeProductId) {
          _isAdFree = true;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('user_premium_status', true);
          notifyListeners();
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
