import 'dart:async';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pdf_export_service.dart';
import '../../../core/database/database.dart';
import '../../document_library/data/document_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

final pdfExportServiceProvider = Provider<PdfExportService>((ref) {
  return PdfExportService();
});

final exportControllerProvider =
    AsyncNotifierProvider<ExportController, String?>(() {
      return ExportController();
    });

class ExportController extends AsyncNotifier<String?> {
  @override
  FutureOr<String?> build() {
    return null;
  }

  Future<void> exportDocument(Document document) async {
    state = const AsyncValue.loading();
    try {
      final exportService = ref.read(pdfExportServiceProvider);
      final repo = ref.read(documentRepositoryProvider);

      final pages = await repo.getPagesForDocument(document.id);

      final dir = await getApplicationDocumentsDirectory();
      final outputPath = p.join(dir.path, '${document.title}.pdf');

      final imagePaths = pages.map((p) => p.compressedImagePath).toList();

      final resultPath = await exportService.generatePdfBackground(
        imagePaths,
        outputPath,
      );

      state = AsyncValue.data(resultPath);
    } catch (e, st) {
      debugPrint('PDF Export failed: $e\n$st');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> exportAllDocuments() async {
    state = const AsyncValue.loading();
    try {
      final exportService = ref.read(pdfExportServiceProvider);
      final repo = ref.read(documentRepositoryProvider);

      final docsStream = repo.watchAllDocuments();
      final docs = await docsStream.first;

      final dir = await getApplicationDocumentsDirectory();
      final outputPath = p.join(dir.path, 'All_Documents_Export.pdf');

      final allImagePaths = <String>[];
      for (final doc in docs) {
        final pages = await repo.getPagesForDocument(doc.id);
        allImagePaths.addAll(pages.map((p) => p.compressedImagePath));
      }

      if (allImagePaths.isEmpty) {
        throw Exception('No documents found to export');
      }

      final resultPath = await exportService.generatePdfBackground(
        allImagePaths,
        outputPath,
      );

      state = AsyncValue.data(resultPath);
    } catch (e, st) {
      debugPrint('PDF Export failed: $e\n$st');
      state = AsyncValue.error(e, st);
    }
  }
}
