import 'package:docscan/features/document_library/presentation/library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(
    // Enforcing Riverpod 3 state management architecture
    const ProviderScope(child: OpenLens()),
  );
}

class OpenLens extends StatelessWidget {
  const OpenLens({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Open Lens',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const LibraryScreen(),
    );
  }
}
