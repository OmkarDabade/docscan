import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/database/database.dart';
import '../application/library_controller.dart';
import 'document_preview_screen.dart';

class DocumentSearchDelegate extends SearchDelegate<Document?> {
  final WidgetRef ref;

  DocumentSearchDelegate(this.ref);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppTheme.surface,
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: AppTheme.textSecondary),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
      ),
      scaffoldBackgroundColor: AppTheme.background,
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear, color: AppTheme.textPrimary),
        onPressed: () {
          if (query.isEmpty) {
            close(context, null);
          } else {
            query = '';
          }
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final docsAsync = ref.watch(documentListProvider);

    return docsAsync.when(
      data: (docs) {
        final results = docs
            .where(
              (doc) => doc.title.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
        if (results.isEmpty) {
          return const Center(
            child: Text(
              'No documents found.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          );
        }
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final doc = results[index];
            return ListTile(
              leading: const Icon(
                Icons.description_outlined,
                color: AppTheme.textSecondary,
              ),
              title: Text(
                doc.title,
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DocumentPreviewScreen(document: doc),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.accent),
      ),
      error: (e, st) => Center(
        child: Text(
          'Error: $e',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}
