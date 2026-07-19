import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ocr/controllers/ocr_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // Section: General Settings
          _buildSectionHeader(context, 'Appearance & Style'),
          
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme Mode'),
            subtitle: Text(_getThemeModeLabel(themeMode)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => _showThemeSelector(context, ref, themeMode),
          ),
          
          const Divider(),

          // Section: Privacy & Data Settings
          _buildSectionHeader(context, 'Privacy & Data'),
          
          ListTile(
            leading: const Icon(Icons.security_outlined),
            title: const Text('Offline Mode Status'),
            subtitle: const Text('100% On-device processing. No telemetry.'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.emerald.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Active',
                style: TextStyle(color: Colors.emerald, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
            title: const Text('Clear Scan History', style: TextStyle(color: Colors.redAccent)),
            subtitle: const Text('Permanently delete all scanned documents'),
            onTap: () => _showClearConfirmation(context, ref),
          ),
          
          const Divider(),

          // Section: About
          _buildSectionHeader(context, 'About'),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OmniOCR Offline v1.0.0',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'A privacy-first OCR engine powered locally on your Android device. It uses Google ML Kit Text Recognition to process scans offline. Your documents and recognized texts never leave your device.',
                      style: TextStyle(height: 1.4, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: isDark ? Colors.white60 : Colors.black54,
            letterSpacing: 0.5,
          ),
      child: Text(title.toUpperCase()),
    );
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.light:
        return 'Light Mode';
      case ThemeMode.dark:
        return 'Dark Mode';
    }
  }

  void _showThemeSelector(BuildContext context, WidgetRef ref, ThemeMode currentMode) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('System Default'),
                value: ThemeMode.system,
                groupValue: currentMode,
                onChanged: (mode) {
                  if (mode != null) {
                    ref.read(themeProvider.notifier).setThemeMode(mode);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Light Mode'),
                value: ThemeMode.light,
                groupValue: currentMode,
                onChanged: (mode) {
                  if (mode != null) {
                    ref.read(themeProvider.notifier).setThemeMode(mode);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark Mode'),
                value: ThemeMode.dark,
                groupValue: currentMode,
                onChanged: (mode) {
                  if (mode != null) {
                    ref.read(themeProvider.notifier).setThemeMode(mode);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showClearConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear Scan History?'),
          content: const Text('This will permanently delete all scans from this device. This operation cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await ref.read(scanHistoryProvider.notifier).clearHistory();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All scan history cleared.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              },
              child: const Text('Clear All', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }
}
