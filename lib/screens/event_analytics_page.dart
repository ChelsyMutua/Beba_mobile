import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';

class EventAnalyticsPage extends StatelessWidget {
  final String eventId;

  const EventAnalyticsPage({Key? key, required this.eventId}) : super(key: key);

  // Dummy data for analytics; replace with real data as needed.
  static const Map<String, double> ticketSales = {
    "Regular": 500,
    "VIP": 200,
    "Early Bird": 100,
    "Student": 150,
  };

  // Define a list of colors corresponding to your ticket types.
  static const List<Color> colorList = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
  ];

  final double bankAmount = 12000; // Dummy bank amount

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Event Analytics"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Ticket Sales",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // Donut (ring) chart using the pie_chart package.
            PieChart(
              dataMap: ticketSales,
              animationDuration: const Duration(milliseconds: 800),
              chartLegendSpacing: 32,
              chartRadius: MediaQuery.of(context).size.width / 3.2,
              colorList: colorList,
              initialAngleInDegree: 0,
              chartType: ChartType.ring, // Ring (donut) chart
              ringStrokeWidth: 32,
              centerText: "Tickets",
              legendOptions: const LegendOptions(
                showLegendsInRow: false,
                legendPosition: LegendPosition.right,
                showLegends: true,
                legendTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              chartValuesOptions: const ChartValuesOptions(
                showChartValues: true,
                showChartValuesInPercentage: true,
                showChartValuesOutside: false,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Bank Amount: \$${bankAmount.toStringAsFixed(2)}",
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}
