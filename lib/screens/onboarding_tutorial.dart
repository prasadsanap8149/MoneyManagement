import 'package:flutter/material.dart';
import 'package:secure_money_management/services/onboarding_service.dart';

/// Interactive onboarding tutorial screen
class OnboardingTutorial extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback? onSkip;

  const OnboardingTutorial({
    super.key,
    required this.onComplete,
    this.onSkip,
  });

  @override
  State<OnboardingTutorial> createState() => _OnboardingTutorialState();
}

class _OnboardingTutorialState extends State<OnboardingTutorial> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingStep> _steps = [
    OnboardingStep(
      title: 'Welcome to SecureMoney! 🎉',
      description:
          'Your personal finance manager with bank-grade security. Let\'s get you started!',
      icon: Icons.account_balance_wallet,
      color: Colors.green,
    ),
    OnboardingStep(
      title: 'Add Your First Transaction 💰',
      description:
          'Tap the + button anywhere in the app to add income or expenses. It\'s that simple!',
      icon: Icons.add_circle,
      color: Colors.blue,
    ),
    OnboardingStep(
      title: 'Track Your Spending 📊',
      description:
          'View detailed reports and analytics to understand your spending patterns and financial health.',
      icon: Icons.analytics,
      color: Colors.purple,
    ),
    OnboardingStep(
      title: 'Secure & Private 🔒',
      description:
          'Your data is encrypted and stored securely on your device. No cloud storage, complete privacy!',
      icon: Icons.security,
      color: Colors.orange,
    ),
    OnboardingStep(
      title: 'Import & Export 📤',
      description:
          'Easily backup your data or import from other apps using JSON, CSV, PDF, or Excel formats.',
      icon: Icons.import_export,
      color: Colors.teal,
    ),
    OnboardingStep(
      title: 'You\'re All Set! 🚀',
      description:
          'Ready to take control of your finances? Let\'s start your financial journey!',
      icon: Icons.rocket_launch,
      color: Colors.green,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeTutorial();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeTutorial() async {
    await OnboardingService.markTutorialAsSeen();
    await OnboardingService.completeFirstLaunch();
    widget.onComplete();
  }

  void _skipTutorial() async {
    await OnboardingService.markTutorialAsSeen();
    await OnboardingService.completeFirstLaunch();
    if (widget.onSkip != null) {
      widget.onSkip!();
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with skip button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Getting Started',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                  ),
                  TextButton(
                    onPressed: _skipTutorial,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: List.generate(
                  _steps.length,
                  (index) => Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: index <= _currentPage
                            ? Colors.green
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Tutorial content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  return _buildTutorialPage(_steps[index]);
                },
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous button
                  _currentPage > 0
                      ? TextButton.icon(
                          onPressed: _previousPage,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey,
                          ),
                        )
                      : const SizedBox(width: 80),

                  // Page indicator text
                  Text(
                    '${_currentPage + 1} of ${_steps.length}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),

                  // Next/Complete button
                  ElevatedButton.icon(
                    onPressed: _nextPage,
                    icon: Icon(
                      _currentPage == _steps.length - 1
                          ? Icons.check
                          : Icons.arrow_forward,
                    ),
                    label: Text(
                      _currentPage == _steps.length - 1
                          ? 'Get Started'
                          : 'Next',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialPage(OnboardingStep step) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: step.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                color: step.color.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              step.icon,
              size: 60,
              color: step.color,
            ),
          ),

          const SizedBox(height: 32),

          // Title
          Text(
            step.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            step.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Achievement badge for completion
          if (_currentPage == _steps.length - 1)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: Colors.green,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Tutorial Complete!',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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

/// Data class for onboarding steps
class OnboardingStep {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
