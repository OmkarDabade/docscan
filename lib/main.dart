import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/document_library/presentation/library_screen.dart';
import 'features/settings/application/theme_provider.dart';

void main() {
  runApp(
    // Enforcing Riverpod 3 state management architecture
    const ProviderScope(child: OpenLens()),
  );
}

class OpenLens extends ConsumerWidget {
  const OpenLens({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Open Lens',
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const LibraryScreen(),
    );
  }
}
