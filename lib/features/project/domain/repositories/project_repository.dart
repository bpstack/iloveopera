import '../entities/edit_project.dart';

/// Persistence contract for editing projects.
///
/// A project = a copy of the PDF (inside app storage) + a JSON snapshot of
/// the annotations. The original PDF is never stored here — only the copy.
abstract class ProjectRepository {
  /// Create or overwrite a project.
  ///
  /// If [existingProjectId] is given the project is overwritten and the PDF
  /// is NOT re-copied (the copy already lives in app storage).
  Future<EditProject> saveProject({
    required String pdfSourcePath,
    required String pdfName,
    required int pageCount,
    required String annotationsJson,
    String? existingProjectId,
  });

  /// Return all saved projects ordered by [EditProject.savedAt] descending.
  Future<List<EditProject>> listProjects();

  /// Load a single project, or `null` if it no longer exists on disk.
  Future<EditProject?> loadProject(String id);

  /// Permanently delete a project and its associated files.
  Future<void> deleteProject(String id);
}
