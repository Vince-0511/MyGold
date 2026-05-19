import 'package:flutter/material.dart';
// ⚠️ Ensure this path points exactly to where your subscription_service.dart file lives
import 'subscription_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Start listening to global subscription changes
    subscriptionService.addListener(_updateUI);
  }

  void _updateUI() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    subscriptionService.removeListener(_updateUI);
    super.dispose();
  }

  /// Wraps service layer triggers with clean visual UI feedback loaders
  Future<void> _executePurchaseFlow() async {
    setState(() => _isProcessing = true);

    try {
      await subscriptionService.buySubscription();
      if (mounted && subscriptionService.isAdFree) {
        _showSuccessSnackBar("Welcome to PRO Status!");
      }
    } catch (e) {
      _showErrorSnackBar("Transaction aborted: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  void _showErrorSnackBar(String err) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPro = subscriptionService.isAdFree;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Premium Dark Slate Background
      appBar: AppBar(
        title: const Text(
          "MyGold Premium",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // 👑 Premium Header Badge
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFBBF24), width: 2),
              ),
              child: const Icon(
                Icons.star_rounded,
                size: 50,
                color: Color(0xFFFBBF24), // Gold Accent
              ),
            ),
            const SizedBox(height: 24),

            Text(
              isPro ? "You are a PRO Member!" : "Upgrade to Pro Tier",
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              isPro
                  ? "Enjoy your complete premium, uninterrupted workspace."
                  : "Track gold rates smoothly without any commercial interruptions.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            ),
            const SizedBox(height: 40),

            // ⚡ Feature Value Props Rows
            _buildFeatureRow(
              Icons.block,
              "Completely Remove All Ads",
              "Clean up your Home Dashboard and Compare Rate list screens instantly.",
            ),
            _buildFeatureRow(
              Icons.bolt,
              "Priority Price Data Stream",
              "Faster server handshake requests during high market volatility.",
            ),
            _buildFeatureRow(
              Icons.support_agent,
              "Direct Developer Support",
              "Get help or suggest custom features straight to the dev branch.",
            ),

            const SizedBox(height: 50),

            // 💰 Dynamic Purchase Layout State
            if (!isPro) ...[
              // Pricing Tag
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "\$1.99 USD / month", // 🎯 Price tier synced
                  style: TextStyle(
                    color: Color(0xFFFBBF24),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Main Action Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFBBF24), // Gold
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  onPressed: _isProcessing ? null : _executePurchaseFlow,
                  child: _isProcessing
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Unlock Ad-Free Mode",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ] else ...[
              // ✅ Verified Emerald Success Active Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF10B981,
                  ).withOpacity(0.1), // Emerald tint
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF10B981), width: 1),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF10B981)),
                    SizedBox(width: 10),
                    Text(
                      "Subscription Active via Sandbox Engine",
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // 🔄 Restore Account Purchases Action Link
            TextButton(
              onPressed: _isProcessing
                  ? null
                  : () async {
                      await subscriptionService.updatePastPurchases();
                      _showSuccessSnackBar(
                        "Checking past sandbox validation tokens...",
                      );
                    },
              child: const Text(
                "Restore Purchases",
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFFBBF24), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
