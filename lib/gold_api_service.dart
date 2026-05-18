import 'package:cloud_firestore/cloud_firestore.dart';

class GoldPricePoint {
  final double day;
  final double price;
  final String dateLabel;

  GoldPricePoint({
    required this.day,
    required this.price,
    required this.dateLabel,
  });
}

class GoldApiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetches cached historical gold prices straight out of Firestore
  Future<List<GoldPricePoint>> fetchCachedHistory() async {
    try {
      // Pulls the latest 7 sequential entries sorted chronologically
      QuerySnapshot snapshot = await _firestore
          .collection('gold_history')
          .orderBy('date', descending: true)
          .limit(7)
          .get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      List<GoldPricePoint> historicalPoints = [];
      // Reverse documents so oldest dates sit cleanly on the left side of your chart
      List<QueryDocumentSnapshot> chronologicalDocs = snapshot.docs
          .toList()
          .reversed
          .toList();

      for (int i = 0; i < chronologicalDocs.length; i++) {
        Map<String, dynamic> data =
            chronologicalDocs[i].data() as Map<String, dynamic>;
        double price = (data['price_per_gram'] as num).toDouble();
        String origDate = data['date'] ?? '';

        // Format string like "2026-05-18" down to a short graph label like "18/05"
        String shortLabel = '';
        if (origDate.length >= 10) {
          shortLabel =
              "${origDate.substring(8, 10)}/${origDate.substring(5, 7)}";
        } else {
          shortLabel = "Day ${i + 1}";
        }

        historicalPoints.add(
          GoldPricePoint(
            day: (i + 1).toDouble(),
            price: price,
            dateLabel: shortLabel,
          ),
        );
      }

      return historicalPoints;
    } catch (e) {
      print("Error fetching cache collection matrix: $e");
      rethrow;
    }
  }
}
