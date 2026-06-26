import 'dart:io';
import 'dart:isolate';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfExportService {
  /// Compiles PDFs on-the-fly inside an isolate
  Future<String> generatePdfBackground(
    List<String> imagePaths,
    String outputPath,
  ) async {
    return await Isolate.run(() async {
      final pdf = pw.Document();

      for (final path in imagePaths) {
        final imageFile = File(path);
        if (!imageFile.existsSync()) continue;

        final imageBytes = await imageFile.readAsBytes();
        final image = pw.MemoryImage(imageBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain));
            },
          ),
        );
      }

      final file = File(outputPath);
      await file.writeAsBytes(await pdf.save());
      return outputPath;
    });
  }
}
