import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:campus_connect/providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Darstellung', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('Systemeinstellung'),
                  secondary: const Icon(Icons.settings_suggest_outlined),
                  value: ThemeMode.system,
                  groupValue: themeProvider.themeMode,
                  onChanged: (value) {
                    if (value == null) return;

                    context.read<ThemeProvider>().setThemeMode(value);
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Hell'),
                  secondary: const Icon(Icons.light_mode_outlined),
                  value: ThemeMode.light,
                  groupValue: themeProvider.themeMode,
                  onChanged: (value) {
                    if (value == null) return;

                    context.read<ThemeProvider>().setThemeMode(value);
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Dunkel'),
                  secondary: const Icon(Icons.dark_mode_outlined),
                  value: ThemeMode.dark,
                  groupValue: themeProvider.themeMode,
                  onChanged: (value) {
                    if (value == null) return;

                    context.read<ThemeProvider>().setThemeMode(value);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
