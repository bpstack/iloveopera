import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/annotation/presentation/providers/annotation_providers.dart';
import '../../../../features/pdf_viewer/presentation/providers/pdf_session_provider.dart';
import '../../data/repositories/raster_pdf_exporter.dart';
import '../../domain/usecases/export_to_new_pdf.dart';

/// Default DPI for rasterisation. 200 balances quality vs. file size (R6).
const int kDefaultExportDpi = 200;

/// Async notifier that drives the export flow.
///
/// [state] is [AsyncLoading] while the PDF is being written,
/// [AsyncData] on success, [AsyncError] on failure.
class ExportNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> exportPdf({int dpi = kDefaultExportDpi}) async {
    // Open OS "Save as…" dialog before starting heavy work
    final result = await getSaveLocation(
      suggestedName: 'anotaciones.pdf',
      acceptedTypeGroups: [
        const XTypeGroup(label: 'PDF', extensions: ['pdf']),
      ],
    );
    if (result == null) return; // user cancelled — keep current state

    state = const AsyncLoading();
    try {
      final dataSource = ref.read(pdfrxDataSourceProvider);
      final doc = dataSource.document;
      if (doc == null) {
        throw StateError('No hay ningún documento abierto.');
      }
      final annotations = ref.read(annotationStoreProvider).listAll();
      final exporter = RasterPdfExporter(
        document: doc,
        annotations: annotations,
      );
      await ExportToNewPdf(exporter)(dpi: dpi, outputPath: result.path);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final exportProvider =
    AsyncNotifierProvider<ExportNotifier, void>(ExportNotifier.new);
