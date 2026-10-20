import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../reader/presentation/viewmodels/reader_view_model.dart';
import '../viewmodels/settings_view_model.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  Future<void> _showAppearanceDialog(
    BuildContext context,
    WidgetRef ref,
    ThemeMode currentMode,
  ) async {
    final selected = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Appearance'),
        children: [
          ListTile(
            leading: Icon(
              currentMode == ThemeMode.system
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: currentMode == ThemeMode.system
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            title: const Text('System default'),
            onTap: () => Navigator.pop(context, ThemeMode.system),
          ),
          ListTile(
            leading: Icon(
              currentMode == ThemeMode.light
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: currentMode == ThemeMode.light
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            title: const Text('Light'),
            onTap: () => Navigator.pop(context, ThemeMode.light),
          ),
          ListTile(
            leading: Icon(
              currentMode == ThemeMode.dark
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: currentMode == ThemeMode.dark
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            title: const Text('Dark'),
            onTap: () => Navigator.pop(context, ThemeMode.dark),
          ),
        ],
      ),
    );

    if (selected != null) {
      await ref.read(settingsViewModelProvider.notifier).setThemeMode(selected);
    }
  }

  Future<void> _showMaxRecentsDialog(
    BuildContext context,
    WidgetRef ref,
    int currentMax,
  ) async {
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Maximum recent files'),
        children: [10, 20, 50].map((count) {
          final isSelected = count == currentMax;
          return ListTile(
            leading: Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
            ),
            title: Text('$count files'),
            onTap: () => Navigator.pop(context, count),
          );
        }).toList(),
      ),
    );

    if (selected != null) {
      await ref
          .read(settingsViewModelProvider.notifier)
          .setMaxRecentFiles(selected);
    }
  }

  Future<void> _confirmClearHistory(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear recent history?'),
        content: const Text(
          'This removes the saved recent-file copies from the app. '
          'It does not delete the original files.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(readerViewModelProvider.notifier).clearRecents();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Recent history cleared')));
      }
    }
  }

  String _appearanceLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System default';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E2128) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF2E333D)
        : const Color(0xFFE5E7EB);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Section: Reading preferences
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Reading preferences',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Material(
            color: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_medium_outlined),
                  title: const Text('Appearance'),
                  subtitle: Text(_appearanceLabel(settings.themeMode)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      _showAppearanceDialog(context, ref, settings.themeMode),
                ),
                Divider(height: 1, indent: 56, color: borderColor),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tune_outlined),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Font size',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Adjust reading text size (${settings.fontSize.toInt()}sp)',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            'A',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Slider(
                              value: settings.fontSize.clamp(12.0, 24.0),
                              min: 12.0,
                              max: 24.0,
                              divisions: 6,
                              onChanged: (val) {
                                ref
                                    .read(settingsViewModelProvider.notifier)
                                    .setFontSize(val);
                              },
                            ),
                          ),
                          const Text(
                            'A',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section: Storage & history
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Storage & history',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Material(
            color: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.copy_outlined),
                  title: const Text('Keep offline copies'),
                  subtitle: const Text('Reopen recent files anytime'),
                  value: settings.keepOfflineCopies,
                  onChanged: (val) {
                    ref
                        .read(settingsViewModelProvider.notifier)
                        .setKeepOfflineCopies(val);
                  },
                ),
                Divider(height: 1, indent: 56, color: borderColor),
                ListTile(
                  leading: const Icon(Icons.history_outlined),
                  title: const Text('Maximum recent files'),
                  subtitle: Text('${settings.maxRecentFiles} files'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showMaxRecentsDialog(
                    context,
                    ref,
                    settings.maxRecentFiles,
                  ),
                ),
                Divider(height: 1, indent: 56, color: borderColor),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Clear recent history'),
                  subtitle: const Text('Also removes cached file copies'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _confirmClearHistory(context, ref),
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),

          // Version footer
          Center(
            child: Text(
              'Markdown Reader · Version 1.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
