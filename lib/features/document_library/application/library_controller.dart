import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../data/document_repository.dart';

final selectedTagProvider = NotifierProvider<SelectedTag, int?>(() {
  return SelectedTag();
});

class SelectedTag extends Notifier<int?> {
  @override
  int? build() => null; // null means 'All Documents'

  void setTag(int? tagId) => state = tagId;
}

final documentListProvider = StreamProvider<List<Document>>((ref) {
  final repo = ref.watch(documentRepositoryProvider);
  final selectedTag = ref.watch(selectedTagProvider);

  if (selectedTag == null) {
    return repo.watchAllDocuments();
  } else {
    return repo.watchDocumentsByTag(selectedTag);
  }
});

final documentPagesProvider = FutureProvider.family<List<DocumentPage>, int>((
  ref,
  documentId,
) {
  final repo = ref.watch(documentRepositoryProvider);
  return repo.getPagesForDocument(documentId);
});

final documentTagsProvider = FutureProvider.family<List<Tag>, int>((
  ref,
  documentId,
) {
  final repo = ref.watch(documentRepositoryProvider);
  return repo.getTagsForDocument(documentId);
});

final singleDocumentProvider = StreamProvider.family<Document, int>((
  ref,
  documentId,
) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(
    db.documents,
  )..where((t) => t.id.equals(documentId))).watchSingle();
});
