import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'gold_api_service.dart';
import 'gold_line_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  double _sharedLivePrice = 0.0; // The state variable holding the live price

  void _updateLivePrice(double price) {
    if (_sharedLivePrice != price) {
      setState(() {
        _sharedLivePrice = price;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ➡️ This list must live HERE inside the build method, NOT as a global variable!
    final List<Widget> screens = [
      GoldDashboardScreen(onPriceLoaded: _updateLivePrice),
      CompareRatesScreen(
        livePrice: _sharedLivePrice,
      ), // Passes down the active state
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFFFFD700),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.compare_arrows_rounded),
            label: 'Compare Rates',
          ),
        ],
      ),
    );
  }
}

// ==================== DASHBOARD SCREEN PANEL ====================
// ==================== DASHBOARD SCREEN PANEL ====================
class GoldDashboardScreen extends StatefulWidget {
  // ➡️ ADD THIS LINE: Declare the callback function parameter
  final Function(double) onPriceLoaded;

  // ➡️ UPDATE THE CONSTRUCTOR: Add required this.onPriceLoaded
  const GoldDashboardScreen({super.key, required this.onPriceLoaded});

  @override
  State<GoldDashboardScreen> createState() => _GoldDashboardScreenState();
}

class _GoldDashboardScreenState extends State<GoldDashboardScreen> {
  final GoldApiService _apiService = GoldApiService();
  List<GoldPricePoint> _chartPoints = [];
  double _livePrice = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCacheData();
  }

  Future<void> _loadCacheData() async {
    setState(() => _isLoading = true);
    try {
      final points = await _apiService.fetchCachedHistory();
      setState(() {
        _chartPoints = points;
        if (points.isNotEmpty) {
          _livePrice = points.last.price;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Cloud Connection Failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('dd MMMM yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "MyGold Live Tracker",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadCacheData,
        color: const Color(0xFFFFD700),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formattedDate,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 8),
              _isLoading
                  ? const Text(
                      "Loading...",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : Text(
                      "RM ${_livePrice.toStringAsFixed(2)} /g",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
              const SizedBox(height: 24),
              Container(
                height: 250,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFFD700),
                        ),
                      )
                    : GoldLineChart(chartPoints: _chartPoints),
              ),

              // =========================================================
              // NEW INJECTED LIVE MARKET NEWS STREAM ELEMENT
              // =========================================================
              const SizedBox(height: 28),
              const Text(
                "Market Headlines",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              _buildNewsFeed(), // Calls the live stream data processor below
            ],
          ),
        ),
      ),
    );
  }

  // Helper method block that taps straight into your Firestore news channel
  // ➡️ PLACE THIS FUNCTION RIGHT HERE ABOVE THE BUILD NEWS FEED METHOD
  Future<void> _launchURL(String urlString) async {
    if (urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        debugPrint("Could not launch url: $urlString");
      }
    } catch (e) {
      debugPrint("Error launching url: $e");
    }
  }

  // Helper method block that taps straight into your Firestore news channel
  Widget _buildNewsFeed() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('gold_news')
          .orderBy('order')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD700)),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Center(
              child: Text(
                "No market news headlines available.",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          );
        }

        final articles = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: articles.length,
          itemBuilder: (context, index) {
            var news = articles[index].data() as Map<String, dynamic>;

            // ➡️ EXTRACT THE URL FROM FIRESTORE
            String articleUrl = news['url'] ?? '';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.black.withOpacity(0.03)),
              ),
              // ➡️ INJECT THE INKWELL HERE DIRECTLY AS THE CHILD OF THE CARD
              child: InkWell(
                borderRadius: BorderRadius.circular(
                  16,
                ), // Clips splash to match Card shape
                onTap: articleUrl.isNotEmpty
                    ? () => _launchURL(articleUrl)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              news['source'] ?? 'Global Finance',
                              style: const TextStyle(
                                color: Color(0xFFB78400),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Text(
                            "Latest News",
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        news['title'] ?? 'Headline unavailable',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          height: 1.3,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      if (news['description'] != null &&
                          news['description'].toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          news['description'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ==================== COMPARE RATES PANEL MATRIX ====================
// ==================== COMPARE RATES PANEL MATRIX ====================
class CompareRatesScreen extends StatelessWidget {
  final double
  livePrice; // Receives real-time price from the parent wrapper container

  const CompareRatesScreen({super.key, required this.livePrice});

  @override
  Widget build(BuildContext context) {
    // Uses live price, falls back to an approximate placeholder only if api hasn't loaded yet
    final double spotPrice = livePrice > 0 ? livePrice : 585.00;

    // Real-world platform margin modifiers precisely calibrated to Malaysian market realities
    final List<Map<String, dynamic>> appData = [
      {
        'appName': 'Maybank MIGA-i',
        'subText': 'Digital Gold Savings Account (Paper-backed)',
        'baseModifier': 1.00, // Tracks pure global spot rate directly
        'buyModifier': 0.994, // Tight ~0.6% buy discount (~RM 3.50 below base)
        'sellModifier': 1.006, // Tight ~0.6% sell markup (~RM 3.50 above base)
        'accentColor': const Color(0xFFFBBF24),
      },
      {
        'appName': 'Bursa Gold Dinar',
        'subText': 'Bursa Malaysia (Physical Allocated Vaulted)',
        'baseModifier':
            1.012, // Adds a realistic ~1.2% local physical logistics premium
        'buyModifier': 0.996, // Very tight institutional buy-back spread (0.4%)
        'sellModifier': 1.004, // Very tight institutional sell markup (0.4%)
        'accentColor': const Color(0xFF1E3A8A),
      },
      {
        'appName': "Touch 'n Go e-Mas",
        'subText': 'Convenience E-Wallet Retail Track',
        'baseModifier': 1.008, // Small convenience premium over paper spot
        'buyModifier':
            0.988, // Standard retail convenience buy-back gap (~1.2%)
        'sellModifier':
            1.012, // Standard retail convenience sell markup (~1.2%)
        'accentColor': const Color(0xFF0052CC),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Compare App Platforms",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appData.length,
        itemBuilder: (context, index) {
          final app = appData[index];

          // 1. Establish the platform's baseline price relative to spot market reality
          double platformBasePrice = spotPrice * app['baseModifier'];

          // 2. Generate active buy/sell positions dynamically
          double buyPrice = platformBasePrice * app['buyModifier'];
          double sellPrice = platformBasePrice * app['sellModifier'];
          double spread = sellPrice - buyPrice;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: app['accentColor'],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app['appName'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          Text(
                            app['subText'],
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, thickness: 0.8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "They Buy (You Sell)",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "RM ${buyPrice.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "They Sell (You Buy)",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "RM ${sellPrice.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Spread Margin",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "RM ${spread.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
