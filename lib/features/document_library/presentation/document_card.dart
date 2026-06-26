import 'package:docscan/core/constants/date_formats.dart';
import 'package:docscan/core/database/database.dart';
import 'package:docscan/core/theme/app_theme.dart';
import 'package:docscan/features/document_library/data/document_repository.dart';
import 'package:docscan/features/document_library/presentation/document_preview_screen.dart';
import 'package:docscan/features/export/application/export_controller.dart';
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
                    child: const Center(
                      child: Icon(
                        Icons.description_outlined,
                        color: AppTheme.textSecondary,
                        size: 32,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.picture_as_pdf,
                            color: AppTheme.accent,
                            size: 20,
                          ),
                          tooltip: 'Export as PDF',
                          onPressed: () {
                            ref
                                .read(exportControllerProvider.notifier)
                                .exportDocument(widget.document);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Exporting PDF...')),
                            );
                          },
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            color: AppTheme.textSecondary,
                            size: 20,
                          ),
                          color: AppTheme.surfaceHighlight,
                          onSelected: (value) {
                            if (value == 'delete') {
                              ref
                                  .read(documentRepositoryProvider)
                                  .deleteDocument(widget.document.id);
                            } else if (value == 'Share') {
                              ref
                                  .read(exportControllerProvider.notifier)
                                  .exportDocument(widget.document);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Exporting PDF...'),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$value option tapped')),
                              );
                            }
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                  value: 'Share',
                                  child: Text(
                                    'Share',
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'Archive',
                                  child: Text(
                                    'Archive',
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                    ),
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
