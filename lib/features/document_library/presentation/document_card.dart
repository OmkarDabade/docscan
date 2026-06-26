import 'dart:io';

import 'package:docscan/core/constants/date_formats.dart';
import 'package:docscan/core/database/database.dart';
import 'package:docscan/core/theme/app_theme.dart';
import 'package:docscan/features/document_library/application/library_controller.dart';
import 'package:docscan/features/document_library/data/document_repository.dart';
import 'package:docscan/features/document_library/presentation/document_preview_screen.dart';
import 'package:docscan/features/export/application/export_controller.dart';
import 'package:docscan/features/tagging/presentation/tag_dialog.dart';
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

  @override
  Widget build(BuildContext context) {
    final pagesAsync = ref.watch(documentPagesProvider(widget.document.id));
    final tagsAsync = ref.watch(documentTagsProvider(widget.document.id));

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
                      onSelected: (value) async {
                        if (value == 'delete') {
                          await ref
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
                          await TagAndRenameDialog.show(
                            context,
                            ref,
                            widget.document.id,
                            widget.document.title,
                          );
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
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
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
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
            tagsAsync.when(
              data: (tags) {
                if (tags.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: tags.map((tag) {
                        return Container(
                          margin: const EdgeInsets.only(right: 4.0),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag.name,
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppTheme.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
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
                pagesAsync.when(
                  data: (pages) => Text(
                    '${pages.length} ${pages.length == 1 ? 'page' : 'pages'}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'Inter',
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
