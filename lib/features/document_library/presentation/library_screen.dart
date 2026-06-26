import 'package:docscan/features/document_library/presentation/document_card.dart';
import 'package:docscan/features/document_library/presentation/tag_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../application/library_controller.dart';
import '../../scanner/application/scanner_controller.dart';
import '../../tagging/data/tag_repository.dart';
import '../../export/application/export_controller.dart';
import '../../settings/presentation/settings_screen.dart';
import 'document_search_delegate.dart';
import 'package:share_plus/share_plus.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Highly efficient selective rebuilds powered by Riverpod 3
    final documentsAsync = ref.watch(documentListProvider);
    final tagsAsync = ref.watch(tagListProvider);
    final selectedTagId = ref.watch(selectedTagProvider);

    ref.listen<AsyncValue<String?>>(exportControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (path) {
          if (path != null) {
            SharePlus.instance.share(
              ShareParams(text: 'Document Export', files: [XFile(path)]),
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
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                          color: AppTheme.textPrimary,
                          fontFamily: 'Inter',
                        ),
                        children: [
                          TextSpan(text: 'LENS_'),
                          TextSpan(
                            text: 'CORE',
                            style: TextStyle(color: AppTheme.accent),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: AppTheme.textSecondary,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // High-performance horizontally scrollable reactive "Tag Tracker"
            SliverToBoxAdapter(
              child: SizedBox(
                height: 32,
                child: tagsAsync.when(
                  data: (tags) => ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      TagPill(
                        label: 'All Documents',
                        isSelected: selectedTagId == null,
                        onTap: () =>
                            ref.read(selectedTagProvider.notifier).setTag(null),
                      ),
                      const SizedBox(width: 8),
                      ...tags.map(
                        (tag) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: TagPill(
                            label: tag.name,
                            isSelected: selectedTagId == tag.id,
                            onTap: () => ref
                                .read(selectedTagProvider.notifier)
                                .setTag(tag.id),
                          ),
                        ),
                      ),
                    ],
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppTheme.accent),
                  ),
                  error: (err, st) => const SizedBox(),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: documentsAsync.when(
                data: (documents) => documents.isEmpty
                    ? const SliverToBoxAdapter(
                        child: Center(
                          child: Text(
                            'No documents found.',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                      )
                    : SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.75,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final doc = documents[index];
                          return DocumentCard(document: doc);
                        }, childCount: documents.length),
                      ),
                loading: () => const SliverToBoxAdapter(
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.accent),
                  ),
                ),
                error: (err, st) => SliverToBoxAdapter(
                  child: Center(
                    child: Text(
                      'Error: $err',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: const FloatingScannerButton(),
    );
  }
}

class FloatingScannerButton extends ConsumerWidget {
  const FloatingScannerButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scannerState = ref.watch(scannerControllerProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            heroTag: 'search',
            onPressed: () {
              showSearch(
                context: context,
                delegate: DocumentSearchDelegate(ref),
              );
            },
            backgroundColor: AppTheme.surface,
            foregroundColor: AppTheme.textSecondary,
            elevation: 0,
            shape: const CircleBorder(
              side: BorderSide(color: AppTheme.surfaceHighlight),
            ),
            child: const Icon(Icons.search),
          ),
          const SizedBox(width: 24),
          SizedBox(
            width: 80,
            height: 80,
            child: FloatingActionButton(
              heroTag: 'scan',
              onPressed: scannerState.isLoading
                  ? null
                  : () => ref
                        .read(scannerControllerProvider.notifier)
                        .captureAndSaveDocument(),
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.background,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
                side: const BorderSide(color: Colors.black, width: 4),
              ),
              child: scannerState.isLoading
                  ? const CircularProgressIndicator(color: AppTheme.background)
                  : Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppTheme.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 24),
          FloatingActionButton(
            heroTag: 'add_tag',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  final tagController = TextEditingController();
                  return AlertDialog(
                    backgroundColor: AppTheme.surface,
                    title: const Text(
                      'Add Tag',
                      style: TextStyle(color: AppTheme.textPrimary),
                    ),
                    content: TextField(
                      controller: tagController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Tag Name',
                        hintStyle: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (tagController.text.trim().isNotEmpty) {
                            ref
                                .read(tagRepositoryProvider)
                                .insertTag(tagController.text.trim());
                            Navigator.pop(context);
                          }
                        },
                        child: const Text(
                          'Add',
                          style: TextStyle(color: AppTheme.accent),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            backgroundColor: AppTheme.surface,
            foregroundColor: AppTheme.textSecondary,
            elevation: 0,
            shape: const CircleBorder(
              side: BorderSide(color: AppTheme.surfaceHighlight),
            ),
            child: const Icon(Icons.local_offer_outlined),
          ),
        ],
      ),
    );
  }
}
