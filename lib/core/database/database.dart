import 'package:drift/drift.dart';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

/// 100% Offline, Privacy-First Storage
/// Images are NEVER stored as blobs. We persist file system paths only.

class Documents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 255)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class DocumentPages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get documentId => integer().references(Documents, #id)();
  TextColumn get originalImagePath => text()();
  TextColumn get compressedImagePath => text()();
  IntColumn get pageIndex => integer()();
}

class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
}

/// Explicit Junction Table for N:M relationships
class DocumentTags extends Table {
  IntColumn get documentId => integer().references(Documents, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();
  @override
  Set<Column> get primaryKey => {documentId, tagId};
}

@DriftDatabase(tables: [Documents, DocumentPages, Tags, DocumentTags])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Seed initial tags
        await into(tags).insert(TagsCompanion.insert(name: 'Financial'));
        await into(tags).insert(TagsCompanion.insert(name: 'Legal'));
        await into(tags).insert(TagsCompanion.insert(name: 'Personal'));
        await into(tags).insert(TagsCompanion.insert(name: 'Identity'));
        await into(tags).insert(TagsCompanion.insert(name: 'Tax_2026'));
        await into(tags).insert(TagsCompanion.insert(name: 'Medical'));
      },
    );
  }
}

LazyDatabase openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'scanner_db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
