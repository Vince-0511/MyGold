import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'gold_api_service.dart';

class GoldLineChart extends StatelessWidget {
  final List<GoldPricePoint> chartPoints;

  const GoldLineChart({super.key, required this.chartPoints});

  @override
  Widget build(BuildContext context) {
    if (chartPoints.isEmpty) {
      return const Center(
        child: Text("No historical chart coordinates available."),
      );
    }

    // Dynamic scale calculations to prevent the line from hitting the roof/floor ceilings
    double minPrice = chartPoints
        .map((p) => p.price)
        .reduce((a, b) => a < b ? a : b);
    double maxPrice = chartPoints
        .map((p) => p.price)
        .reduce((a, b) => a > b ? a : b);
    double padding = (maxPrice - minPrice) * 0.15 == 0
        ? 10
        : (maxPrice - minPrice) * 0.15;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.withOpacity(0.15), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                int index = value.toInt() - 1;
                if (index >= 0 && index < chartPoints.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    key: ValueKey('lbl_$index'),
                    child: Text(
                      chartPoints[index].dateLabel,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                return Text(
                  "RM${value.toStringAsFixed(0)}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 1,
        maxX: chartPoints.length.toDouble(),
        minY: minPrice - padding,
        maxY: maxPrice + padding,
        lineBarsData: [
          LineChartBarData(
            spots: chartPoints.map((p) => FlSpot(p.day, p.price)).toList(),
            isCurved: true,
            color: const Color(0xFFFFD700), // Solid Gold
            barWidth: 3.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(
                0xFFFFD700,
              ).withOpacity(0.12), // Subtle gradient shadow drop
            ),
          ),
        ],
      ),
    );
  }
}
