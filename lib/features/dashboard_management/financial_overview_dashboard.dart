import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:carousel_slider/carousel_slider.dart';

class FinancialOverviewDashboard extends StatelessWidget {
  const FinancialOverviewDashboard({super.key, required String title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Overview'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              _buildCarousel(),
              const SizedBox(height: 20),
              _buildFinancialChart(),
              const SizedBox(height: 20),
              _buildRecentTransactions(),
              const SizedBox(height: 20),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  // Carousel for financial highlights
  Widget _buildCarousel() {
    final List<String> images = [
      'assets/financial1.png', // Replace with your asset paths
      'assets/financial2.png',
      'assets/financial3.png',
    ];

    return CarouselSlider(
      options: CarouselOptions(
        autoPlay: true,
        height: 200,
        enlargeCenterPage: true,
      ),
      items: images.map((image) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(image: AssetImage(image), fit: BoxFit.cover),
          ),
        );
      }).toList(),
    );
  }

  // Financial chart section using Syncfusion
  Widget _buildFinancialChart() {
    final List<ChartData> chartData = [
      ChartData('Q1', 1500),
      ChartData('Q2', 3000),
      ChartData('Q3', 2500),
      ChartData('Q4', 4000),
    ];

    return Neumorphic(
      style: const NeumorphicStyle(
        depth: 8,
        intensity: 0.5,
        color: Colors.white,
      ),
      child: Container(
        height: 300,
        padding: const EdgeInsets.all(16.0),
        child: SfCartesianChart(
          primaryYAxis: const NumericAxis(labelFormat: '{value}'),
          primaryXAxis: const CategoryAxis(),
          title: const ChartTitle(text: 'Quarterly Revenue'),
          series: <CartesianSeries>[
            ColumnSeries<ChartData, String>(
              dataSource: chartData,
              xValueMapper: (ChartData data, _) => data.quarter,
              yValueMapper: (ChartData data, _) => data.sales,
              name: 'Revenue',
              color: Colors.blueAccent,
            )
          ],
        ),
      ),
    );
  }

  // Recent transactions section
  Widget _buildRecentTransactions() {
    return Neumorphic(
      style: const NeumorphicStyle(
        depth: 8,
        intensity: 0.5,
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Recent Transactions",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent),
            ),
          ),
          ..._buildTransactionCards(),
        ],
      ),
    );
  }

  // Individual transaction cards
  List<Widget> _buildTransactionCards() {
    final List<Map<String, dynamic>> transactions = [
      {"title": "Invoice #1234", "amount": "\$1500", "date": "2024-09-01"},
      {"title": "Payment Received", "amount": "\$2000", "date": "2024-09-05"},
      {"title": "Invoice #5678", "amount": "\$1200", "date": "2024-09-10"},
    ];

    return transactions.map((transaction) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Neumorphic(
          style: const NeumorphicStyle(
            depth: 4,
            intensity: 0.4,
            color: Colors.white,
          ),
          child: ListTile(
            title: Text(transaction['title']),
            subtitle: Text(transaction['date']),
            trailing: Text(transaction['amount'],
                style: const TextStyle(color: Colors.green)),
            onTap: () {
              _showTransactionDetails(transaction['title']);
            },
          ),
        ),
      );
    }).toList();
  }

  // Action buttons at the bottom
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        ElevatedButton(
          onPressed: () {
            _showPopup(context, "Add Transaction", "Create a new transaction");
          },
          child: const Text("Add Transaction"),
        ),
        ElevatedButton(
          onPressed: () {
            _showPopup(context, "Generate Report", "Generate financial report");
          },
          child: const Text("Generate Report"),
        ),
      ],
    );
  }

  // Function to show transaction details
  void _showTransactionDetails(String title) {
    // Show a popup or a dialog with details
    print("Details for $title");
  }

  // Function to show a custom popup
  void _showPopup(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

// Model for chart data
class ChartData {
  final String quarter;
  final int sales;

  ChartData(this.quarter, this.sales);
}
