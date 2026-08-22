import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_connect/screens/admin_reports_screen.dart';
import 'package:campus_connect/services/admin_service.dart';
import 'package:campus_connect/providers/theme_provider.dart';
import 'package:flutter/foundation.dart';

import 'package:campus_connect/config/firebase_emulator_config.dart';
import 'package:campus_connect/services/account_deletion_service.dart';


class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  static final AdminService _adminService = AdminService();

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Abmelden?'),
          content: const Text(
            'Möchtest du dich wirklich aus Campus Connect abmelden?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Abmelden'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    try {
      await FirebaseAuth.instance.signOut();
    } on FirebaseAuthException catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Die Abmeldung ist fehlgeschlagen.'),
        ),
      );
    }
  }

Future<void> _testAccountDeletionRequest(BuildContext context) async {
  final service = AccountDeletionService();

  try {
    final result = await service.requestAccountDeletion();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${result.allowed}: ${result.message}',
        ),
      ),
    );
  } on AccountDeletionException catch (error) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${error.code}: ${error.message}',
        ),
      ),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

   return Scaffold(
  appBar: AppBar(
    title: const Text('Einstellungen'),
  ),
  body: ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(
        'Darstellung',
        style: Theme.of(context).textTheme.titleMedium,
      ),
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

      const SizedBox(height: 24),

      Text(
        'Konto',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 12),

      Card(
        child: ListTile(
          leading: Icon(
            Icons.logout,
            color: Theme.of(context).colorScheme.error,
          ),
          title: Text(
            'Abmelden',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          subtitle: const Text(
            'Du wirst zum Anmeldebildschirm zurückgeleitet.',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _confirmLogout(context),
        ),
      ),

      if (kDebugMode && useFirebaseEmulators) ...[
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.science_outlined),
            title: const Text('Accountlöschung testen'),
            subtitle: const Text(
              'Prüft nur die Berechtigung im Firebase Emulator.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _testAccountDeletionRequest(context),
          ),
        ),
      ],

      const SizedBox(height: 12),

            FutureBuilder<bool>(
        future: _adminService.isCurrentUserAdmin(),
        builder: (context, snapshot) {
          final isAdmin = snapshot.data ?? false;

          if (!isAdmin) {
            return const SizedBox.shrink();
          }

          return ListTile(
            leading: const Icon(
              Icons.admin_panel_settings_outlined,
            ),
            title: const Text('Administration'),
            subtitle: const Text(
              'Gemeldete Beiträge verwalten',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AdminReportsScreen(),
                ),
              );
            },
          );
        },
      ),
    ],
  ),
);
  }
}