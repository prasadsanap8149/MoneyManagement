import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

class ThemeSettingsWidget extends StatelessWidget {
  const ThemeSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Card(
          margin: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.palette,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Theme Settings',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Current theme: ${themeService.currentThemeName}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8.0,
                  children: [
                    _ThemeButton(
                      title: 'System',
                      icon: Icons.settings_system_daydream,
                      mode: ThemeMode.system,
                      isSelected: themeService.themeMode == ThemeMode.system,
                      onPressed: () => themeService.setThemeMode(ThemeMode.system),
                    ),
                    _ThemeButton(
                      title: 'Light',
                      icon: Icons.light_mode,
                      mode: ThemeMode.light,
                      isSelected: themeService.themeMode == ThemeMode.light,
                      onPressed: () => themeService.setThemeMode(ThemeMode.light),
                    ),
                    _ThemeButton(
                      title: 'Dark',
                      icon: Icons.dark_mode,
                      mode: ThemeMode.dark,
                      isSelected: themeService.themeMode == ThemeMode.dark,
                      onPressed: () => themeService.setThemeMode(ThemeMode.dark),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ThemeButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final ThemeMode mode;
  final bool isSelected;
  final VoidCallback onPressed;

  const _ThemeButton({
    required this.title,
    required this.icon,
    required this.mode,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(title),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onPressed(),
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }
}

/// Simple theme toggle button that can be added to app bars
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return IconButton(
          icon: Icon(
            themeService.themeMode == ThemeMode.dark
                ? Icons.light_mode
                : themeService.themeMode == ThemeMode.light
                    ? Icons.dark_mode
                    : Icons.auto_mode,
          ),
          onPressed: () => themeService.toggleTheme(),
          tooltip: 'Toggle theme (Current: ${themeService.currentThemeName})',
        );
      },
    );
  }
}
