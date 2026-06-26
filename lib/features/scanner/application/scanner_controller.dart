import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'scanner_service.dart';
import '../../document_library/data/document_repository.dart';

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

  Future<void> captureAndSaveDocument() async {
    state = const AsyncValue.loading();
    try {
      final scanner = ref.read(scannerServiceProvider);
      final repo = ref.read(documentRepositoryProvider);

      final imagePaths = await scanner.captureDocuments();

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

        final title = 'Scan_${DateTime.now().millisecondsSinceEpoch}';
        await repo.insertDocument(title, compressedPaths);
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
