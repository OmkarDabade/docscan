import 'dart:io';

import 'package:docscan/core/constants/date_formats.dart';
import 'package:docscan/core/database/database.dart';
import 'package:docscan/core/theme/app_theme.dart';
import 'package:docscan/features/document_library/application/library_controller.dart';
import 'package:docscan/features/document_library/data/document_repository.dart';
import 'package:docscan/features/document_library/presentation/document_preview_screen.dart';
import 'package:docscan/features/export/application/export_controller.dart';
import 'package:docscan/features/tagging/data/tag_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DocumentCard extends ConsumerStatefulWidget {
  final Document document;

  const DocumentCard({super.key, required this.document});

  @override
  ConsumerState<DocumentCard> createState() => _DocumentCardState();
}

class _DocumentCardState extends ConsumerState<DocumentCard> {
  bool _isEditing = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.document.title);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();

    super.dispose();
  }

  void _saveTitle() {
    final newTitle = _controller.text.trim();
    if (newTitle.isNotEmpty && newTitle != widget.document.title) {
      ref
          .read(documentRepositoryProvider)
          .updateDocumentTitle(widget.document.id, newTitle);
    } else {
      _controller.text = widget.document.title;
    }
    setState(() {
      _isEditing = false;
    });
  }

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
  Widget build(BuildContext context) {
    final pagesAsync = ref.watch(documentPagesProvider(widget.document.id));

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DocumentPreviewScreen(document: widget.document),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.surfaceHighlight),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceHighlight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: pagesAsync.when(
                      data: (pages) {
                        if (pages.isNotEmpty) {
                          return Image.file(
                            File(pages.first.compressedImagePath),
                            fit: BoxFit.cover,
                          );
                        }
                        return const Center(
                          child: Icon(
                            Icons.description_outlined,
                            color: AppTheme.textSecondary,
                            size: 32,
                          ),
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.accent,
                        ),
                      ),
                      error: (err, st) => const Center(
                        child: Icon(Icons.error_outline, color: Colors.red),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: PopupMenuButton<String>(
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
                              .deleteDocument(widget.document.id);
                        } else if (value == 'export') {
                          ref
                              .read(exportControllerProvider.notifier)
                              .exportDocument(widget.document);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Exporting PDF...')),
                          );
                        } else if (value == 'tag') {
                          _showTagDialog(context, ref, widget.document.id);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$value option coming soon'),
                            ),
                          );
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
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
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _isEditing
                ? TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _saveTitle(),
                    onTapOutside: (_) => _saveTitle(),
                    autofocus: true,
                  )
                : GestureDetector(
                    onTap: () {
                      setState(() {
                        _isEditing = true;
                      });
                      _focusNode.requestFocus();
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.document.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.edit,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  defaultDateFormat.format(widget.document.createdAt),
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'Inter',
                    color: AppTheme.textSecondary,
                  ),
                ),
                const Text(
                  'RAW',
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'Inter',
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
