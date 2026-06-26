import 'package:docscan/features/document_library/application/library_controller.dart';
import 'package:docscan/features/document_library/data/document_repository.dart';
import 'package:docscan/features/export/application/export_controller.dart';
import 'package:docscan/features/scanner/application/scanner_controller.dart';
import 'package:docscan/features/tagging/data/tag_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/database.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Highly efficient selective rebuilds powered by Riverpod 3
    final documentsAsync = ref.watch(documentListProvider);
    final tagsAsync = ref.watch(tagListProvider);
    final selectedTagId = ref.watch(selectedTagProvider);

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
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
            // High-performance horizontally scrollable reactive "Tag Tracker"
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
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
            onPressed: () {},
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
            heroTag: 'filter',
            onPressed: () {},
            backgroundColor: AppTheme.surface,
            foregroundColor: AppTheme.textSecondary,
            elevation: 0,
            shape: const CircleBorder(
              side: BorderSide(color: AppTheme.surfaceHighlight),
            ),
            child: const Icon(Icons.tune),
          ),
        ],
      ),
    );
  }
}

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
    return Container(
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
                                  style: TextStyle(color: AppTheme.textPrimary),
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'Archive',
                                child: Text(
                                  'Archive',
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
                '${widget.document.createdAt.month}/${widget.document.createdAt.day}/${widget.document.createdAt.year}',
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
    );
  }
}

class TagPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const TagPill({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accent : AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppTheme.accent : AppTheme.surfaceHighlight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
