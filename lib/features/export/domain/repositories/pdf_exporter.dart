/// Contract for the PDF export engine.
///
/// The domain layer defines only this interface; the data layer provides
/// [RasterPdfExporter] (Opción A: rasterise + overlay). See ROADMAP §2.4.
abstract class PdfExporter {
  /// Render all pages of the current document at [dpi] (pixels per inch),
  /// draw [annotations] on top, and write the result to [outputPath].
  ///
  /// The original PDF is **never** modified — the output is always a new file.
  Future<void> export({required int dpi, required String outputPath});
}
