import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../document_library/data/document_repository.dart';
import '../../tagging/data/tag_repository.dart';
import '../../../core/database/database.dart';
import '../../document_library/application/library_controller.dart';

class TagAndRenameDialog extends ConsumerStatefulWidget {
  final int documentId;
  final String initialTitle;

  const TagAndRenameDialog({
    super.key,
    required this.documentId,
    required this.initialTitle,
  });

  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    int documentId,
    String initialTitle,
  ) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TagAndRenameDialog(
        documentId: documentId,
        initialTitle: initialTitle,
      ),
    );
  }

  @override
  ConsumerState<TagAndRenameDialog> createState() => _TagAndRenameDialogState();
}

class _TagAndRenameDialogState extends ConsumerState<TagAndRenameDialog> {
  late TextEditingController _titleController;
  final TextEditingController _newTagController = TextEditingController();
  List<Tag> _allTags = [];
  Set<int> _selectedTagIds = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final tagsRepo = ref.read(tagRepositoryProvider);
      final docRepo = ref.read(documentRepositoryProvider);

      final allTags = await tagsRepo.getAllTags();
      final docTags = await docRepo.getTagsForDocument(widget.documentId);

      if (mounted) {
        setState(() {
          _allTags = allTags;
          _selectedTagIds = docTags.map((t) => t.id).toSet();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _newTagController.dispose();
    super.dispose();
  }

  Future<void> _createNewTag() async {
    final name = _newTagController.text.trim();
    if (name.isEmpty) return;

    try {
      final tagsRepo = ref.read(tagRepositoryProvider);
      await tagsRepo.insertTag(name);
      _newTagController.clear();

      // Reload tags and auto-select newly created tag
      final updatedTags = await tagsRepo.getAllTags();
      final newTag = updatedTags.firstWhere(
        (t) => t.name.toLowerCase() == name.toLowerCase(),
      );

      await ref
          .read(documentRepositoryProvider)
          .addTagToDocument(widget.documentId, newTag.id);

      setState(() {
        _allTags = updatedTags;
        _selectedTagIds.add(newTag.id);
      });

      // Refresh global stream
      ref.invalidate(tagListProvider);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create tag: $e')));
    }
  }

  Future<void> _saveAndClose() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final docRepo = ref.read(documentRepositoryProvider);
      final newTitle = _titleController.text.trim();

      if (newTitle.isNotEmpty && newTitle != widget.initialTitle) {
        await docRepo.updateDocumentTitle(widget.documentId, newTitle);
      }

      // Invalidate providers to force reactivity across library & cards
      ref.invalidate(documentListProvider);
      ref.invalidate(documentPagesProvider(widget.documentId));
      ref.invalidate(documentTagsProvider(widget.documentId));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document settings updated successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving changes: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.accent),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Document Settings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'DOCUMENT TITLE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.background,
                        hintText: 'Enter title',
                        hintStyle: const TextStyle(
                          color: AppTheme.textSecondary,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'TAGS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_allTags.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'No tags available.',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _allTags.map((tag) {
                          final isSelected = _selectedTagIds.contains(tag.id);
                          return FilterChip(
                            label: Text(tag.name),
                            selected: isSelected,
                            onSelected: (selected) async {
                              final docRepo = ref.read(
                                documentRepositoryProvider,
                              );
                              if (selected) {
                                await docRepo.addTagToDocument(
                                  widget.documentId,
                                  tag.id,
                                );
                                setState(() {
                                  _selectedTagIds.add(tag.id);
                                });
                              } else {
                                await docRepo.removeTagFromDocument(
                                  widget.documentId,
                                  tag.id,
                                );
                                setState(() {
                                  _selectedTagIds.remove(tag.id);
                                });
                              }
                              ref.invalidate(
                                documentTagsProvider(widget.documentId),
                              );
                            },
                            selectedColor: AppTheme.accent.withOpacity(0.2),
                            checkmarkColor: AppTheme.accent,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppTheme.accent
                                  : AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            backgroundColor: AppTheme.background,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isSelected
                                    ? AppTheme.accent
                                    : AppTheme.surfaceHighlight,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _newTagController,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppTheme.background,
                              hintText: 'Add new tag...',
                              hintStyle: const TextStyle(
                                color: AppTheme.textSecondary,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _createNewTag,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.surfaceHighlight,
                            foregroundColor: AppTheme.accent,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Icon(Icons.add, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveAndClose,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Save & Close',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
