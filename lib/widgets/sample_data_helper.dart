import 'package:flutter/material.dart';

/// Widget to show sample data when the app is empty
class SampleDataHelper {
  static List<SampleTransaction> getSampleTransactions() {
    return [
      SampleTransaction(
        amount: 5000.0,
        type: 'Income',
        category: 'Salary',
        description: 'Monthly salary',
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
      SampleTransaction(
        amount: 1200.0,
        type: 'Expense',
        category: 'Rent',
        description: 'Monthly rent payment',
        date: DateTime.now().subtract(const Duration(days: 2)),
      ),
      SampleTransaction(
        amount: 350.0,
        type: 'Expense',
        category: 'Groceries',
        description: 'Weekly grocery shopping',
        date: DateTime.now().subtract(const Duration(days: 3)),
      ),
      SampleTransaction(
        amount: 150.0,
        type: 'Expense',
        category: 'Transport',
        description: 'Monthly bus pass',
        date: DateTime.now().subtract(const Duration(days: 4)),
      ),
      SampleTransaction(
        amount: 2000.0,
        type: 'Income',
        category: 'Freelance',
        description: 'Freelance project payment',
        date: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }

  static Widget buildSampleDataPrompt({
    required VoidCallback onLoadSample,
    required VoidCallback onAddFirst,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              size: 40,
              color: Colors.blue,
            ),
          ),

          const SizedBox(height: 24),

          // Title
          const Text(
            'New to SecureMoney?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Description
          const Text(
            'Would you like to explore the app with sample data, or start fresh with your own transactions?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Sample data button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onLoadSample,
              icon: const Icon(Icons.preview),
              label: const Text('Explore with Sample Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Start fresh button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAddFirst,
              icon: const Icon(Icons.add),
              label: const Text('Start with My Data'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.green),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Info text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.amber.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.amber,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sample data can be cleared anytime from settings',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber,
                    ),
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

/// Data class for sample transactions
class SampleTransaction {
  final double amount;
  final String type;
  final String category;
  final String description;
  final DateTime date;

  SampleTransaction({
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    required this.date,
  });
}
