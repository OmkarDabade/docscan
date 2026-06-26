import 'dart:async';
import 'package:docscan/core/constants/date_formats.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'scanner_service.dart';
import '../../document_library/data/document_repository.dart';
import '../../document_library/application/library_controller.dart';

final scannerServiceProvider = Provider<ScannerService>((ref) {
  return ScannerService();
});

final scannerControllerProvider =
    AsyncNotifierProvider<ScannerController, void>(() {
      return ScannerController();
    });

class ScannerController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    return null;
  }

  Future<int?> captureAndSaveDocument() async {
    state = const AsyncValue.loading();
    try {
      final scanner = ref.read(scannerServiceProvider);
      final repo = ref.read(documentRepositoryProvider);

      final imagePaths = await scanner.captureDocuments();

      int? docId;
      if (imagePaths != null && imagePaths.isNotEmpty) {
        // Run compression pipeline in background isolate to keep 120 FPS
        final compressedPaths = <String>[];
        for (final path in imagePaths) {
          final targetPath = '${path}_compressed.jpg';
          final compressed = await scanner.compressImageBackground(
            path,
            targetPath,
          );
          compressedPaths.add(compressed);
        }

        final title = 'Scan ${defaultDateFormat.format(DateTime.now())}';
        docId = await repo.insertDocument(title, compressedPaths);
      }
      state = const AsyncValue.data(null);
      return docId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> appendPageToDocument(int documentId) async {
    state = const AsyncValue.loading();
    try {
      final scanner = ref.read(scannerServiceProvider);
      final repo = ref.read(documentRepositoryProvider);

      final imagePaths = await scanner.captureDocuments();
      if (imagePaths != null && imagePaths.isNotEmpty) {
        for (final path in imagePaths) {
          final targetPath =
              '${path}_compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final compressed = await scanner.compressImageBackground(
            path,
            targetPath,
          );
          await repo.addPageToDocument(documentId, compressed);
        }
        ref.invalidate(documentPagesProvider(documentId));
        ref.invalidate(documentListProvider);
        state = const AsyncValue.data(null);
        return true;
      }
      state = const AsyncValue.data(null);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
