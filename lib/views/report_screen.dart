import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:secure_money_management/ad_service/widgets/banner_ad.dart';
import 'package:secure_money_management/helper/constants.dart';

import '../models/transaction_model.dart';

class ReportsScreen extends StatelessWidget {
  final List<TransactionModel> transactions;

  const ReportsScreen({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final totalIncome = transactions
        .where((txn) => txn.type == 'Income')
        .fold(0.0, (sum, txn) => sum + txn.amount);
    final totalExpenses = transactions
        .where((txn) => txn.type == 'Expense')
        .fold(0.0, (sum, txn) => sum + txn.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (Constants.isMobileDevice) const GetBannerAd(),
            const SizedBox(height: 20),
            SizedBox(
              height: 300, // Define a height for the PieChart
              child: PieChart(
                PieChartData(
                  sections: [
                    if (totalIncome > 0)
                      PieChartSectionData(
                        value: totalIncome,
                        color: Colors.green,
                        title: 'Income',
                        radius: 60,
                      ),
                    if (totalExpenses > 0)
                      PieChartSectionData(
                        value: totalExpenses,
                        color: Colors.red,
                        title: 'Expenses',
                        radius: 60,
                      ),
                  ],
                  centerSpaceRadius: 40,
                  borderData: FlBorderData(show: false),
                  // Optional: hides borders
                  sectionsSpace: 0, // Space between sections
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
