import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter/foundation.dart'; // 🎯 Required for kDebugMode

final subscriptionService = SubscriptionService();

class SubscriptionService extends ChangeNotifier {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  // 🎯 Globally tracks if the user has unlocked the ad-free experience
  bool _isAdFree = false;
  bool get isAdFree => _isAdFree;

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

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
    updatePastPurchases();
  }

  // Fetch product price details ($1.99 USD) dynamically from Google Play
  Future<void> loadProducts() async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) return;

    const Set<String> ids = {adFreeProductId};
    final ProductDetailsResponse response = await _inAppPurchase
        .queryProductDetails(ids);

    _products = response.productDetails;
    notifyListeners();
  }

  // Trigger the official Google Play checkout sheet
  Future<void> buySubscription() async {
    if (kDebugMode) {
      print("🛠️ Debug Mode detected: Simulating purchase handshake...");
      _isAdFree = true;
      notifyListeners();
      return; // Stop execution here so it doesn't hit the empty array block below
    }
    if (_products.isEmpty) return;

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: _products.first,
    );
    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  // Check if user already owns the subscription when app launches
  Future<void> updatePastPurchases() async {
    // Note: In production apps, validating purchase tokens via a backend server
    // or Firebase Cloud Function is highly recommended to prevent fraud.
    await _inAppPurchase.restorePurchases();
  }

  void _listenToPurchaseUpdated(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show a loading indicator in your UI if needed
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        print("Purchase Error: ${purchaseDetails.error}");
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Check if the verified item matches our ad-free ID string
        if (purchaseDetails.productID == adFreeProductId) {
          _isAdFree = true;
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
