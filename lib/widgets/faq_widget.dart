import 'package:flutter/material.dart';

/// Simple FAQ widget for common questions
class FAQWidget extends StatefulWidget {
  const FAQWidget({super.key});

  @override
  State<FAQWidget> createState() => _FAQWidgetState();
}

class _FAQWidgetState extends State<FAQWidget> {
  int? _expandedIndex;

  final List<FAQItem> _faqItems = [
    FAQItem(
      category: 'Getting Started',
      question: 'How do I add my first transaction?',
      answer: 'Tap the + (plus) button on any screen to add a new transaction. Choose between Income or Expense, select a category, enter the amount, and save.',
    ),
    FAQItem(
      category: 'Getting Started',
      question: 'Can I create custom categories?',
      answer: 'Yes! When adding a transaction, select "Other" as the category and you can enter your own custom category name.',
    ),
    FAQItem(
      category: 'Data Management',
      question: 'How do I backup my data?',
      answer: 'Go to Recent Transactions screen and use the export options. You can export to JSON, CSV, PDF, or Excel formats.',
    ),
    FAQItem(
      category: 'Data Management',
      question: 'Can I import data from other apps?',
      answer: 'Yes! You can import JSON files from SecureMoney exports or properly formatted CSV files through the import feature.',
    ),
    FAQItem(
      category: 'Security',
      question: 'Is my financial data secure?',
      answer: 'Absolutely! All your data is encrypted using bank-grade security and stored only on your device. No cloud storage means complete privacy.',
    ),
    FAQItem(
      category: 'Security',
      question: 'Where is my data stored?',
      answer: 'Your data is stored locally on your device using encrypted storage. It never leaves your device unless you manually export it.',
    ),
    FAQItem(
      category: 'Features',
      question: 'How do I view spending reports?',
      answer: 'Tap on the Reports tab to see detailed charts and analytics of your income, expenses, and spending patterns.',
    ),
    FAQItem(
      category: 'Features',
      question: 'Can I filter my transactions?',
      answer: 'Yes! In the Transactions screen, you can search and filter by type, category, date range, and payment mode.',
    ),
    FAQItem(
      category: 'Common Problems',
      question: 'My transactions are not showing up',
      answer: 'This usually happens due to a sync issue. Try restarting the app. If the problem persists, check if you have any active filters that might be hiding transactions.',
    ),
    FAQItem(
      category: 'Common Problems',
      question: 'How do I delete a transaction?',
      answer: 'In the Transactions screen, find the transaction you want to delete and tap the Delete button. Confirm the deletion when prompted.',
    ),
    FAQItem(
      category: 'Advanced Features',
      question: 'Can I set up recurring transactions?',
      answer: 'Currently, SecureMoney doesn\'t support automatic recurring transactions, but you can easily duplicate a transaction by editing an existing one.',
    ),
    FAQItem(
      category: 'Advanced Features',
      question: 'How do I change the app theme?',
      answer: 'Go to the Settings (gear icon) in the Dashboard and select your preferred theme - Light, Dark, or System.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Group FAQs by category
    final Map<String, List<FAQItem>> groupedFAQs = {};
    for (final item in _faqItems) {
      groupedFAQs.putIfAbsent(item.category, () => []).add(item);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Frequently Asked Questions'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade50, Colors.green.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.help_outline,
                  size: 40,
                  color: Colors.green,
                ),
                SizedBox(height: 12),
                Text(
                  'How can we help you?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Find answers to common questions about SecureMoney',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // FAQ sections
          ...groupedFAQs.entries.map((entry) {
            return _buildFAQSection(entry.key, entry.value);
          }),

          // Contact section
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.support_agent,
                  size: 32,
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Still need help?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'If you can\'t find the answer you\'re looking for, you can re-run the tutorial from Settings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // This would trigger the tutorial from settings
                  },
                  icon: const Icon(Icons.school),
                  label: const Text('Restart Tutorial'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection(String category, List<FAQItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            category,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ),

        // FAQ items
        ...items.asMap().entries.map((entry) {
          final globalIndex = _faqItems.indexOf(entry.value);
          return _buildFAQItem(entry.value, globalIndex);
        }),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFAQItem(FAQItem item, int index) {
    final isExpanded = _expandedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              item.question,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.green,
            ),
            onTap: () {
              setState(() {
                _expandedIndex = isExpanded ? null : index;
              });
            },
          ),
          if (isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                item.answer,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Data class for FAQ items
class FAQItem {
  final String category;
  final String question;
  final String answer;

  FAQItem({
    required this.category,
    required this.question,
    required this.answer,
  });
}
