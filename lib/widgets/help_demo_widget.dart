import 'package:flutter/material.dart';

/// Widget to show a demo video or help content
class HelpDemoWidget extends StatefulWidget {
  const HelpDemoWidget({super.key});

  @override
  State<HelpDemoWidget> createState() => _HelpDemoWidgetState();
}

class _HelpDemoWidgetState extends State<HelpDemoWidget> {
  int _currentStep = 0;
  
  final List<DemoStep> _demoSteps = [
    DemoStep(
      title: 'Add Transactions',
      description: 'Tap the + button to add income or expenses',
      icon: Icons.add_circle,
      color: Colors.green,
      tips: [
        'Choose between Income and Expense',
        'Select a category or create custom ones',
        'Add payment mode for better tracking',
      ],
    ),
    DemoStep(
      title: 'View Reports',
      description: 'Analyze your spending patterns with charts',
      icon: Icons.bar_chart,
      color: Colors.blue,
      tips: [
        'Monthly and yearly breakdowns',
        'Category-wise spending analysis',
        'Income vs Expense trends',
      ],
    ),
    DemoStep(
      title: 'Backup Data',
      description: 'Export to JSON, CSV, PDF, or Excel',
      icon: Icons.backup,
      color: Colors.orange,
      tips: [
        'Secure local storage only',
        'Multiple export formats',
        'Easy import from other apps',
      ],
    ),
    DemoStep(
      title: 'Stay Secure',
      description: 'Bank-grade encryption keeps your data safe',
      icon: Icons.security,
      color: Colors.red,
      tips: [
        'All data encrypted locally',
        'No cloud storage required',
        'Complete privacy guaranteed',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How SecureMoney Works'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Demo steps indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(
                _demoSteps.length,
                (index) => Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentStep = index),
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: index <= _currentStep
                            ? Colors.green
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Demo content
          Expanded(
            child: PageView.builder(
              onPageChanged: (index) => setState(() => _currentStep = index),
              itemCount: _demoSteps.length,
              itemBuilder: (context, index) {
                return _buildDemoStep(_demoSteps[index]);
              },
            ),
          ),

          // Navigation
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _currentStep > 0
                      ? () => setState(() => _currentStep--)
                      : null,
                  child: const Text('Previous'),
                ),
                Text(
                  '${_currentStep + 1} of ${_demoSteps.length}',
                  style: const TextStyle(color: Colors.grey),
                ),
                TextButton(
                  onPressed: _currentStep < _demoSteps.length - 1
                      ? () => setState(() => _currentStep++)
                      : () => Navigator.pop(context),
                  child: Text(_currentStep < _demoSteps.length - 1 ? 'Next' : 'Done'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoStep(DemoStep step) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Icon and title
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: step.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              step.icon,
              size: 50,
              color: step.color,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            step.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            step.description,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Tips section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates,
                      color: step.color,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Quick Tips:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...step.tips.map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 6, right: 12),
                          decoration: BoxDecoration(
                            color: step.color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            tip,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
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

/// Data class for demo steps
class DemoStep {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> tips;

  DemoStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.tips,
  });
}
