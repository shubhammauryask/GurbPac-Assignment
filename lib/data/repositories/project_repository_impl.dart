import '../../core/errors/failures.dart';
import '../../domain/entities/org_member.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../datasources/taskflow_mock_datasource.dart';
import '../models/project_model.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final TaskFlowMockDataSource _dataSource;

  ProjectRepositoryImpl(this._dataSource);

  @override
  Future<List<Project>> getProjects(String orgId) async {
    await _dataSource.init();
    return await _dataSource.getProjects(orgId);
  }

  @override
  Future<Project> getProjectById(String projectId) async {
    await _dataSource.init();
    return await _dataSource.getProjectById(projectId);
  }

  @override
  Future<Project> createProject({
    required String orgId,
    required String name,
    required String description,
    required String createdBy,
  }) async {
    await _dataSource.init();

    if (name.trim().isEmpty) {
      throw const ValidationException('Project name cannot be empty', code: 'EMPTY_NAME');
    }

    final newProject = ProjectModel(
      id: 'proj-${DateTime.now().millisecondsSinceEpoch}',
      orgId: orgId,
      name: name.trim(),
      description: description.trim(),
      createdBy: createdBy,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await _dataSource.createProject(newProject);
  }

  @override
  Future<Project> updateProject(Project project) async {
    await _dataSource.init();

    if (project.name.trim().isEmpty) {
      throw const ValidationException('Project name cannot be empty', code: 'EMPTY_NAME');
    }

    final model = ProjectModel(
      id: project.id,
      orgId: project.orgId,
      name: project.name.trim(),
      description: project.description.trim(),
      createdBy: project.createdBy,
      createdAt: project.createdAt,
      updatedAt: DateTime.now(),
    );

    return await _dataSource.updateProject(model);
  }

  @override
  Future<void> deleteProject({
    required String projectId,
    required String requestingUserId,
    required OrgRole userRole,
  }) async {
    await _dataSource.init();

    // Business-logic authorization guard
    if (userRole != OrgRole.orgAdmin) {
      throw const PermissionException(
        '403 Forbidden: Only organization administrators are permitted to delete projects.',
        code: 'FORBIDDEN_ADMIN_ACTION',
      );
    }

    await _dataSource.deleteProject(projectId);
  }
}
