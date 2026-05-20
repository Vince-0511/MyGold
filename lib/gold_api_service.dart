import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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

  Future<List<GoldPricePoint>> fetchCachedHistory() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('gold_history')
          .orderBy('date', descending: true)
          .limit(7)
          .get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      List<GoldPricePoint> historicalPoints = [];
      List<QueryDocumentSnapshot> chronologicalDocs =
          snapshot.docs.toList().reversed.toList();

      for (int i = 0; i < chronologicalDocs.length; i++) {
        Map<String, dynamic> data =
            chronologicalDocs[i].data() as Map<String, dynamic>;
        double price = (data['price_per_gram'] as num).toDouble();
        String origDate = data['date'] ?? '';

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
      debugPrint("Error fetching gold history: $e");
      rethrow;
    }
  }
}
