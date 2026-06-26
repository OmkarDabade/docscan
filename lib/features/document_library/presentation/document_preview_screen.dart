import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/database/database.dart';
import '../data/document_repository.dart';
import '../../export/application/export_controller.dart';
import '../../tagging/presentation/tag_dialog.dart';
import '../application/library_controller.dart';

class DocumentPreviewScreen extends ConsumerWidget {
  final Document document;

  const DocumentPreviewScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final docAsync = ref.watch(singleDocumentProvider(document.id));
    final currentDoc = docAsync.value ?? document;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: Text(
          currentDoc.title,
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: AppTheme.textSecondary,
              size: 24,
            ),
            color: AppTheme.surface,
            onSelected: (value) async {
              if (value == 'delete') {
                await ref
                    .read(documentRepositoryProvider)
                    .deleteDocument(document.id);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } else if (value == 'export') {
                ref
                    .read(exportControllerProvider.notifier)
                    .exportDocument(currentDoc);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exporting PDF...')),
                );
              } else if (value == 'tag') {
                await TagAndRenameDialog.show(
                  context,
                  ref,
                  document.id,
                  currentDoc.title,
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'export',
                child: Row(
                  children: [
                    Icon(
                      Icons.share_outlined,
                      size: 18,
                      color: AppTheme.textPrimary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Share as PDF',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'tag',
                child: Row(
                  children: [
                    Icon(
                      Icons.local_offer_outlined,
                      size: 18,
                      color: AppTheme.textPrimary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Manage Tags',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.redAccent,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Delete',
                      style: TextStyle(color: Colors.redAccent, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<DocumentPage>>(
        future: ref
            .read(documentRepositoryProvider)
            .getPagesForDocument(document.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading pages: ${snapshot.error}',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }

          final pages = snapshot.data ?? [];
          if (pages.isEmpty) {
            return const Center(
              child: Text(
                'No pages found for this document.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pages.length,
            itemBuilder: (context, index) {
              final page = pages[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.surfaceHighlight),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(page.compressedImagePath),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox(
                        height: 200,
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            color: AppTheme.textSecondary,
                            size: 48,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
