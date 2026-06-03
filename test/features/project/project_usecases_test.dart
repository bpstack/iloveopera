import 'package:flutter_test/flutter_test.dart';
import 'package:iloveopera/features/project/domain/entities/edit_project.dart';
import 'package:iloveopera/features/project/domain/repositories/project_repository.dart';
import 'package:iloveopera/features/project/domain/usecases/delete_project.dart';
import 'package:iloveopera/features/project/domain/usecases/list_projects.dart';
import 'package:iloveopera/features/project/domain/usecases/save_project.dart';

class _InMemoryProjectRepo implements ProjectRepository {
  final Map<String, EditProject> _store = {};
  int _counter = 0;

  @override
  Future<EditProject> saveProject({
    required String pdfSourcePath,
    required String pdfName,
    required int pageCount,
    required String annotationsJson,
    String? existingProjectId,
  }) async {
    final id = existingProjectId ?? 'proj-${++_counter}';
    final project = EditProject(
      id: id,
      name: pdfName,
      savedAt: DateTime.now(),
      pageCount: pageCount,
      pdfCopyPath: '/app/$id/document.pdf',
      projectJsonPath: '/app/$id/project.json',
    );
    _store[id] = project;
    return project;
  }

  @override
  Future<List<EditProject>> listProjects() async =>
      _store.values.toList()..sort((a, b) => b.savedAt.compareTo(a.savedAt));

  @override
  Future<EditProject?> loadProject(String id) async => _store[id];

  @override
  Future<void> deleteProject(String id) async => _store.remove(id);
}

void main() {
  late _InMemoryProjectRepo repo;
  late SaveProject save;
  late ListProjects list;
  late DeleteProject delete;

  setUp(() {
    repo = _InMemoryProjectRepo();
    save = SaveProject(repo);
    list = ListProjects(repo);
    delete = DeleteProject(repo);
  });

  group('SaveProject', () {
    test('creates a new project', () async {
      final p = await save(
        pdfSourcePath: '/tmp/doc.pdf',
        pdfName: 'doc.pdf',
        pageCount: 3,
        annotationsJson: '{"version":1,"annotations":[]}',
      );
      expect(p.name, 'doc.pdf');
      expect(p.pageCount, 3);
      expect(p.id, isNotEmpty);
    });

    test('overwrites an existing project when id provided', () async {
      final first = await save(
        pdfSourcePath: '/tmp/doc.pdf',
        pdfName: 'doc.pdf',
        pageCount: 1,
        annotationsJson: '{"version":1,"annotations":[]}',
      );
      final second = await save(
        pdfSourcePath: '/tmp/doc.pdf',
        pdfName: 'doc-updated.pdf',
        pageCount: 2,
        annotationsJson: '{"version":1,"annotations":[]}',
        existingProjectId: first.id,
      );
      expect(second.id, first.id);
      expect(second.name, 'doc-updated.pdf');
    });
  });

  group('ListProjects', () {
    test('returns empty list when no projects', () async {
      expect(await list(), isEmpty);
    });

    test('returns all saved projects', () async {
      await save(
        pdfSourcePath: '/tmp/a.pdf',
        pdfName: 'a.pdf',
        pageCount: 1,
        annotationsJson: '{"version":1,"annotations":[]}',
      );
      await save(
        pdfSourcePath: '/tmp/b.pdf',
        pdfName: 'b.pdf',
        pageCount: 2,
        annotationsJson: '{"version":1,"annotations":[]}',
      );
      expect(await list(), hasLength(2));
    });
  });

  group('DeleteProject', () {
    test('removes an existing project', () async {
      final p = await save(
        pdfSourcePath: '/tmp/x.pdf',
        pdfName: 'x.pdf',
        pageCount: 1,
        annotationsJson: '{"version":1,"annotations":[]}',
      );
      await delete(p.id);
      expect(await list(), isEmpty);
    });

    test('is idempotent for unknown id', () async {
      await expectLater(delete('nonexistent'), completes);
    });
  });
}
