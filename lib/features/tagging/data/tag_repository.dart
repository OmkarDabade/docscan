import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../document_library/data/document_repository.dart';
import 'package:drift/drift.dart';

abstract class ITagRepository {
  Stream<List<Tag>> watchAllTags();
  Future<List<Tag>> getAllTags();
  Future<int> insertTag(String name);
  Future<void> attachTagToDocument(int documentId, int tagId);
}

final tagRepositoryProvider = Provider<ITagRepository>((ref) {
  return TagRepository(ref.watch(appDatabaseProvider));
});

class TagRepository implements ITagRepository {
  final AppDatabase db;

  TagRepository(this.db);

  @override
  Stream<List<Tag>> watchAllTags() {
    return db.select(db.tags).watch();
  }

  @override
  Future<List<Tag>> getAllTags() {
    return db.select(db.tags).get();
  }

  @override
  Future<int> insertTag(String name) {
    return db
        .into(db.tags)
        .insert(
          TagsCompanion.insert(name: name),
          mode: InsertMode.insertOrIgnore,
        );
  }

  @override
  Future<void> attachTagToDocument(int documentId, int tagId) async {
    await db
        .into(db.documentTags)
        .insert(
          DocumentTagsCompanion.insert(documentId: documentId, tagId: tagId),
          mode: InsertMode.insertOrIgnore,
        );
  }
}

final tagListProvider = StreamProvider<List<Tag>>((ref) {
  return ref.watch(tagRepositoryProvider).watchAllTags();
});
