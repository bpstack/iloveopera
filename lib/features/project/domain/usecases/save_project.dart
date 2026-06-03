import '../entities/edit_project.dart';
import '../repositories/project_repository.dart';

class SaveProject {
  const SaveProject(this._repo);
  final ProjectRepository _repo;

  /// Persist the current editing session as a project.
  ///
  /// [annotationsJson] is the serialised output of [AnnotationStore.toJson].
  Future<EditProject> call({
    required String pdfSourcePath,
    required String pdfName,
    required int pageCount,
    required String annotationsJson,
    String? existingProjectId,
  }) =>
      _repo.saveProject(
        pdfSourcePath: pdfSourcePath,
        pdfName: pdfName,
        pageCount: pageCount,
        annotationsJson: annotationsJson,
        existingProjectId: existingProjectId,
      );
}
