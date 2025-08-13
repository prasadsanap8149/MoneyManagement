import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle gamification features like achievements and rewards
class GamificationService {
  static const String _achievementsKey = 'user_achievements';
  static const String _statsKey = 'user_stats';
  
  /// Check if user has earned any new achievements
  static Future<List<Achievement>> checkForNewAchievements({
    required int totalTransactions,
    required int totalCategories,
    required double totalAmount,
    required bool hasUsedExport,
    required bool hasUsedImport,
    required bool hasUsedReports,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final currentAchievements = prefs.getStringList(_achievementsKey) ?? [];
    final newAchievements = <Achievement>[];
    
    // Define all possible achievements
    final Map<String, Achievement> allAchievements = {
      'first_transaction': Achievement(
        id: 'first_transaction',
        title: 'First Step! 🎉',
        description: 'Added your first transaction',
        icon: Icons.add_circle,
        color: Colors.green,
        condition: () => totalTransactions >= 1,
      ),
      'ten_transactions': Achievement(
        id: 'ten_transactions',
        title: 'Getting Started! 💪',
        description: 'Added 10 transactions',
        icon: Icons.trending_up,
        color: Colors.blue,
        condition: () => totalTransactions >= 10,
      ),
      'fifty_transactions': Achievement(
        id: 'fifty_transactions',
        title: 'Transaction Master! 🏆',
        description: 'Added 50 transactions',
        icon: Icons.star,
        color: Colors.orange,
        condition: () => totalTransactions >= 50,
      ),
      'hundred_transactions': Achievement(
        id: 'hundred_transactions',
        title: 'Finance Pro! 🌟',
        description: 'Added 100 transactions',
        icon: Icons.workspace_premium,
        color: Colors.purple,
        condition: () => totalTransactions >= 100,
      ),
      'category_explorer': Achievement(
        id: 'category_explorer',
        title: 'Category Explorer! 📊',
        description: 'Used 5 different categories',
        icon: Icons.category,
        color: Colors.teal,
        condition: () => totalCategories >= 5,
      ),
      'big_spender': Achievement(
        id: 'big_spender',
        title: 'Big Numbers! 💰',
        description: 'Tracked over ₹10,000 in transactions',
        icon: Icons.account_balance,
        color: Colors.indigo,
        condition: () => totalAmount >= 10000,
      ),
      'data_manager': Achievement(
        id: 'data_manager',
        title: 'Data Manager! 💾',
        description: 'Used export feature',
        icon: Icons.backup,
        color: Colors.cyan,
        condition: () => hasUsedExport,
      ),
      'power_user': Achievement(
        id: 'power_user',
        title: 'Power User! ⚡',
        description: 'Used all major features',
        icon: Icons.electric_bolt,
        color: Colors.amber,
        condition: () => hasUsedExport && hasUsedImport && hasUsedReports,
      ),
    };
    
    // Check each achievement
    for (final achievement in allAchievements.values) {
      if (!currentAchievements.contains(achievement.id) && achievement.condition()) {
        newAchievements.add(achievement);
        currentAchievements.add(achievement.id);
      }
    }
    
    // Save updated achievements
    if (newAchievements.isNotEmpty) {
      await prefs.setStringList(_achievementsKey, currentAchievements);
    }
    
    return newAchievements;
  }
  
  /// Show achievement notification
  static void showAchievementNotification(BuildContext context, Achievement achievement) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: achievement.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  achievement.icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      achievement.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      achievement.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.celebration,
                color: Colors.white,
                size: 24,
              ),
            ],
          ),
        ),
        backgroundColor: achievement.color,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  /// Get all earned achievements
  static Future<List<String>> getEarnedAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_achievementsKey) ?? [];
  }
  
  /// Update user statistics
  static Future<void> updateStats({
    int? transactionCount,
    double? totalAmount,
    bool? hasUsedExport,
    bool? hasUsedImport,
    bool? hasUsedReports,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (transactionCount != null) {
      await prefs.setInt('stat_transactions', transactionCount);
    }
    if (totalAmount != null) {
      await prefs.setDouble('stat_total_amount', totalAmount);
    }
    if (hasUsedExport != null) {
      await prefs.setBool('stat_used_export', hasUsedExport);
    }
    if (hasUsedImport != null) {
      await prefs.setBool('stat_used_import', hasUsedImport);
    }
    if (hasUsedReports != null) {
      await prefs.setBool('stat_used_reports', hasUsedReports);
    }
  }
  
  /// Mark a feature as used
  static Future<void> markFeatureUsed(String feature) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('used_$feature', true);
  }
  
  /// Check if a feature has been used
  static Future<bool> hasUsedFeature(String feature) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('used_$feature') ?? false;
  }
}

/// Data class for achievements
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool Function() condition;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.condition,
  });
}
