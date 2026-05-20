import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'gold_api_service.dart';
import 'gold_line_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'native_ad_widget.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'subscription_service.dart';
import 'subscription_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  double _sharedLivePrice = 0.0;

  void _updateLivePrice(double price) {
    if (_sharedLivePrice != price) {
      setState(() {
        _sharedLivePrice = price;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Screens must be built inside build() so they receive the current state values.
    final List<Widget> screens = [
      GoldDashboardScreen(onPriceLoaded: _updateLivePrice),
      CompareRatesScreen(livePrice: _sharedLivePrice),
      SubscriptionScreen(),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money_rounded),
            label: 'Subscription',
          ),
        ],
      ),
    );
  }
}

class GoldDashboardScreen extends StatefulWidget {
  final Function(double) onPriceLoaded;

  const GoldDashboardScreen({super.key, required this.onPriceLoaded});

  @override
  State<GoldDashboardScreen> createState() => _GoldDashboardScreenState();
}

class _GoldDashboardScreenState extends State<GoldDashboardScreen> {
  final GoldApiService _apiService = GoldApiService();
  List<GoldPricePoint> _chartPoints = [];
  double _livePrice = 0.0;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    subscriptionService.addListener(_updateUI);
    _loadCacheData();
  }

  void _updateUI() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    subscriptionService.removeListener(_updateUI);
    super.dispose();
  }

  Future<void> _loadCacheData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final points = await _apiService.fetchCachedHistory();
      if (!mounted) return;
      setState(() {
        _chartPoints = points;
        if (points.isNotEmpty) {
          _livePrice = points.last.price;
          widget.onPriceLoaded(_livePrice);
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      debugPrint("Cloud connection failed: $e");
    }
  }

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

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('dd MMMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "MyGold Tracker",
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
                  : _hasError
                  ? GestureDetector(
                      onTap: _loadCacheData,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Could not load price",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Tap to retry",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
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
                      color: Colors.black.withValues(alpha: 0.04),
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
                    : _hasError
                    ? Center(
                        child: GestureDetector(
                          onTap: _loadCacheData,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.wifi_off_rounded,
                                color: Colors.grey,
                                size: 36,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Connection failed — tap to retry",
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : GoldLineChart(chartPoints: _chartPoints),
              ),
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
              _buildNewsFeed(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsFeed() {
    final showAds = !subscriptionService.isAdFree;

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
          itemCount: showAds ? articles.length + 1 : articles.length,
          itemBuilder: (context, index) {
            if (showAds && index == 0) {
              return const NativeAdWidget();
            }

            int articleIndex = showAds ? index - 1 : index;
            var news = articles[articleIndex].data() as Map<String, dynamic>;
            String articleUrl = news['url'] ?? '';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.black.withValues(alpha: 0.03)),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
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
                              color: const Color(0xFFFFD700).withValues(alpha: 0.15),
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

// ==================== COMPARE RATES SCREEN ====================
class CompareRatesScreen extends StatefulWidget {
  final double livePrice;

  const CompareRatesScreen({super.key, required this.livePrice});

  @override
  State<CompareRatesScreen> createState() => _CompareRatesScreenState();
}

class _CompareRatesScreenState extends State<CompareRatesScreen> {
  NativeAd? _compareNativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    subscriptionService.addListener(_onSubscriptionChanged);
    _loadCompareAd();
  }

  void _onSubscriptionChanged() {
    if (subscriptionService.isAdFree && mounted) {
      setState(() => _isAdLoaded = false);
      _compareNativeAd?.dispose();
    }
  }

  void _loadCompareAd() {
    if (subscriptionService.isAdFree) {
      setState(() => _isAdLoaded = false);
      return;
    }
    _compareNativeAd = NativeAd(
      adUnitId: kReleaseMode
          ? 'ca-app-pub-8958676039974787/7863548301'
          : 'ca-app-pub-3940256099942544/2247696110',
      factoryId: 'listTile',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          setState(() => _isAdLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Compare page ad failed to load: $error');
        },
      ),
    );

    _compareNativeAd!.load();
  }

  @override
  void dispose() {
    subscriptionService.removeListener(_onSubscriptionChanged);
    _compareNativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double spotPrice = widget.livePrice > 0 ? widget.livePrice : 585.00;

    final List<Map<String, dynamic>> appData = [
      {
        'appName': 'Maybank MIGA-i',
        'subText': 'Digital Gold Savings Account (Paper-backed)',
        'baseModifier': 1.00,
        'buyModifier': 0.994,
        'sellModifier': 1.006,
        'accentColor': const Color(0xFFFBBF24),
      },
      {
        'appName': 'Bursa Gold Dinar',
        'subText': 'Bursa Malaysia (Physical Allocated Vaulted)',
        'baseModifier': 1.012,
        'buyModifier': 0.996,
        'sellModifier': 1.004,
        'accentColor': const Color(0xFF1E3A8A),
      },
      {
        'appName': "Touch 'n Go e-Mas",
        'subText': 'Convenience E-Wallet Retail Track',
        'baseModifier': 1.008,
        'buyModifier': 0.988,
        'sellModifier': 1.012,
        'accentColor': const Color(0xFF0052CC),
      },
      {
        'appName': 'Moomoo MY (GOLDETF)',
        'subText': 'Bursa Malaysia Exchange-Traded Fund (0828EA)',
        'baseModifier': 1.001,
        'buyModifier': 0.997,
        'sellModifier': 1.003,
        'accentColor': const Color(0xFF14B8A6),
      },
      {
        'appName': 'Versa Gold',
        'subText': 'AHAM Shariah Gold Tracker Fund (Asset Managed)',
        'baseModifier': 1.003,
        'buyModifier': 0.995,
        'sellModifier': 1.005,
        'accentColor': const Color(0xFF6366F1),
      },
      {
        'appName': 'CGS International (CGSI)',
        'subText': 'Bursa Malaysia Derivatives (Gold Futures Contract)',
        'baseModifier': 1.005,
        'buyModifier': 0.992,
        'sellModifier': 1.008,
        'accentColor': const Color(0xFFEF4444),
      },
    ];

    int totalListItemCount = appData.length + (_isAdLoaded ? 1 : 0);

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
        itemCount: totalListItemCount,
        itemBuilder: (context, index) {
          if (_isAdLoaded && index == 2) {
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AdWidget(ad: _compareNativeAd!),
              ),
            );
          }

          final int adjustedDataIndex =
              (_isAdLoaded && index > 2) ? index - 1 : index;
          final app = appData[adjustedDataIndex];

          double platformBasePrice = spotPrice * app['baseModifier'];
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
                  color: Colors.black.withValues(alpha: 0.03),
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
