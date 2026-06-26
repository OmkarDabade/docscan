import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import 'package:drift/drift.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

abstract class IDocumentRepository {
  Stream<List<Document>> watchAllDocuments();
  Stream<List<Document>> watchDocumentsByTag(int tagId);
  Future<List<DocumentPage>> getPagesForDocument(int documentId);
  Future<List<Tag>> getTagsForDocument(int documentId);
  Future<void> addTagToDocument(int documentId, int tagId);
  Future<void> removeTagFromDocument(int documentId, int tagId);
  Future<int> insertDocument(String title, List<String> imagePaths);
  Future<void> updateDocumentTitle(int id, String newTitle);
  Future<void> deleteDocument(int id);
}

final documentRepositoryProvider = Provider<IDocumentRepository>((ref) {
  return DocumentRepository(ref.watch(appDatabaseProvider));
});

class DocumentRepository implements IDocumentRepository {
  final AppDatabase db;

  DocumentRepository(this.db);

  @override
  Stream<List<Document>> watchAllDocuments() {
    return db.select(db.documents).watch();
  }

  @override
  Stream<List<Document>> watchDocumentsByTag(int tagId) {
    final query = db.select(db.documents).join([
      innerJoin(
        db.documentTags,
        db.documentTags.documentId.equalsExp(db.documents.id),
      ),
    ])..where(db.documentTags.tagId.equals(tagId));

    return query.map((row) => row.readTable(db.documents)).watch();
  }

  @override
  Future<List<DocumentPage>> getPagesForDocument(int documentId) {
    return (db.select(
      db.documentPages,
    )..where((tbl) => tbl.documentId.equals(documentId))).get();
  }

  @override
  Future<List<Tag>> getTagsForDocument(int documentId) {
    final query = db.select(db.tags).join([
      innerJoin(db.documentTags, db.documentTags.tagId.equalsExp(db.tags.id)),
    ])..where(db.documentTags.documentId.equals(documentId));
    return query.map((row) => row.readTable(db.tags)).get();
  }

  @override
  Future<void> addTagToDocument(int documentId, int tagId) async {
    await db
        .into(db.documentTags)
        .insert(
          DocumentTagsCompanion.insert(documentId: documentId, tagId: tagId),
          mode: InsertMode.insertOrIgnore,
        );
  }

  @override
  Future<void> removeTagFromDocument(int documentId, int tagId) async {
    await (db.delete(db.documentTags)..where(
          (tbl) => tbl.documentId.equals(documentId) & tbl.tagId.equals(tagId),
        ))
        .go();
  }

  @override
  Future<int> insertDocument(String title, List<String> imagePaths) async {
    return await db.transaction(() async {
      final documentId = await db
          .into(db.documents)
          .insert(DocumentsCompanion.insert(title: title));

      for (int i = 0; i < imagePaths.length; i++) {
        await db
            .into(db.documentPages)
            .insert(
              DocumentPagesCompanion.insert(
                documentId: documentId,
                originalImagePath: imagePaths[i],
                compressedImagePath:
                    imagePaths[i], // Initially same, compression isolate updates this
                pageIndex: i,
              ),
            );
      }
      return documentId;
    });
  }

  @override
  Future<void> updateDocumentTitle(int id, String newTitle) async {
    await (db.update(db.documents)..where((tbl) => tbl.id.equals(id))).write(
      DocumentsCompanion(title: Value(newTitle)),
    );
  }

  @override
  Future<void> deleteDocument(int id) async {
    await db.transaction(() async {
      await (db.delete(
        db.documentPages,
      )..where((tbl) => tbl.documentId.equals(id))).go();
      await (db.delete(
        db.documentTags,
      )..where((tbl) => tbl.documentId.equals(id))).go();
      await (db.delete(db.documents)..where((tbl) => tbl.id.equals(id))).go();
    });
  }
}
