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
