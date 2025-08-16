import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage onboarding and tutorial state
class OnboardingService {
  static const String _isFirstLaunchKey = 'is_first_launch';
  static const String _hasSeenTutorialKey = 'has_seen_tutorial';
  static const String _completedStepsKey = 'completed_onboarding_steps';
  
  /// Check if this is the first time the app is launched
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isFirstLaunchKey) ?? true;
  }
  
  /// Mark first launch as completed
  static Future<void> completeFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isFirstLaunchKey, false);
  }
  
  /// Check if user has seen the tutorial
  static Future<bool> hasSeenTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenTutorialKey) ?? false;
  }
  
  /// Mark tutorial as seen
  static Future<void> markTutorialAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenTutorialKey, true);
  }
  
  /// Reset tutorial state (for re-running from settings)
  static Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenTutorialKey, false);
    await prefs.remove(_completedStepsKey);
  }
  
  /// Get completed onboarding steps
  static Future<List<String>> getCompletedSteps() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_completedStepsKey) ?? [];
  }
  
  /// Mark an onboarding step as completed
  static Future<void> completeStep(String stepId) async {
    final prefs = await SharedPreferences.getInstance();
    final completedSteps = await getCompletedSteps();
    if (!completedSteps.contains(stepId)) {
      completedSteps.add(stepId);
      await prefs.setStringList(_completedStepsKey, completedSteps);
    }
  }
  
  /// Check if a specific step is completed
  static Future<bool> isStepCompleted(String stepId) async {
    final completedSteps = await getCompletedSteps();
    return completedSteps.contains(stepId);
  }
}
