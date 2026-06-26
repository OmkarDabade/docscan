import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/database/database.dart';
import '../data/document_repository.dart';
import '../../export/application/export_controller.dart';
import '../../tagging/data/tag_repository.dart';

class DocumentPreviewScreen extends ConsumerWidget {
  final Document document;

  const DocumentPreviewScreen({super.key, required this.document});

  void _showTagDialog(
    BuildContext context,
    WidgetRef ref,
    int documentId,
  ) async {
    final tags = await ref.read(tagListProvider.future);
    final documentTags = await ref
        .read(documentRepositoryProvider)
        .getTagsForDocument(documentId);
    final documentTagIds = documentTags.map((t) => t.id).toSet();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              title: const Text(
                'Manage Tags',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: tags.length,
                  itemBuilder: (context, index) {
                    final tag = tags[index];
                    final isSelected = documentTagIds.contains(tag.id);
                    return CheckboxListTile(
                      title: Text(
                        tag.name,
                        style: const TextStyle(color: AppTheme.textPrimary),
                      ),
                      value: isSelected,
                      activeColor: AppTheme.accent,
                      onChanged: (bool? value) async {
                        if (value == true) {
                          await ref
                              .read(documentRepositoryProvider)
                              .addTagToDocument(documentId, tag.id);
                          setState(() {
                            documentTagIds.add(tag.id);
                          });
                        } else {
                          await ref
                              .read(documentRepositoryProvider)
                              .removeTagFromDocument(documentId, tag.id);
                          setState(() {
                            documentTagIds.remove(tag.id);
                          });
                        }
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: AppTheme.accent),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

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

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: Text(
          document.title,
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
            onSelected: (value) {
              if (value == 'delete') {
                ref
                    .read(documentRepositoryProvider)
                    .deleteDocument(document.id);
                Navigator.pop(context);
              } else if (value == 'export') {
                ref
                    .read(exportControllerProvider.notifier)
                    .exportDocument(document);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exporting PDF...')),
                );
              } else if (value == 'tag') {
                _showTagDialog(context, ref, document.id);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$value option coming soon')),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'export',
                child: Text(
                  'Share as PDF',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'tag',
                child: Text(
                  'Manage Tags',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text(
                  'Delete',
                  style: TextStyle(color: Colors.redAccent),
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
