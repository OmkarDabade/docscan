import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../application/theme_provider.dart';
import '../../export/application/export_controller.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);

    ref.listen<AsyncValue<String?>>(exportControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (path) {
          if (path != null) {
            SharePlus.instance.share(
              ShareParams(text: 'All Documents Export', files: [XFile(path)]),
            );

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Exported to: $path')));
          }
        },
        error: (err, st) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Export failed: $err')));
        },
      );
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        backgroundColor: AppTheme.surface,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.palette_outlined, color: AppTheme.accent),
            title: const Text(
              'Theme',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            subtitle: Text(
              isDark ? 'Dark Mode' : 'Light Mode',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            trailing: Switch(
              value: isDark,
              onChanged: (val) {
                ref.read(themeProvider.notifier).toggleTheme(val);
              },
              activeThumbColor: AppTheme.accent,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.save_alt, color: AppTheme.accent),
            title: const Text(
              'Export All Data',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            subtitle: const Text(
              'Backup your documents',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            onTap: () {
              ref.read(exportControllerProvider.notifier).exportAllDocuments();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting all data...')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: AppTheme.accent),
            title: const Text(
              'About',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            subtitle: const Text(
              'Version 1.0.0',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
