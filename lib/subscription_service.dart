import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

final subscriptionService = SubscriptionService();

class SubscriptionService extends ChangeNotifier {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  bool _isAdFree = false;
  bool get isAdFree => _isAdFree;

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  // Set to true to simulate a successful purchase in debug/profile mode.
  // Must be false before publishing to Google Play.
  final bool _isTestingSandbox = false;

  static const String adFreeProductId = 'remove_ads_subscription';

  void initialize() {
    _subscription = _inAppPurchase.purchaseStream.listen(
      _listenToPurchaseUpdated,
      onDone: () => _subscription.cancel(),
      onError: (error) => debugPrint("Purchase stream error: $error"),
    );

    loadProducts();
    _loadLocalBackupStatus();
  }

  Future<void> _loadLocalBackupStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('user_premium_status') == true) {
      _isAdFree = true;
      notifyListeners();
    }
  }

  Future<void> loadProducts() async {
    if (_isTestingSandbox) return;

    final bool available = await _inAppPurchase.isAvailable();
    if (!available) return;

    const Set<String> ids = {adFreeProductId};
    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(ids);

    _products = response.productDetails;
    notifyListeners();
  }

  Future<void> buySubscription() async {
    if (_isTestingSandbox) {
      debugPrint("Sandbox: simulating successful purchase...");
      await Future.delayed(const Duration(seconds: 2));
      _isAdFree = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_premium_status', true);
      notifyListeners();
      return;
    }

    if (_products.isEmpty) return;

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: _products.first,
    );
    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

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
        // UI loading state handled by caller
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        debugPrint("Purchase error: ${purchaseDetails.error}");
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
