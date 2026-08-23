import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import 'auth_provider.dart';
import 'core_providers.dart';

class ProjectListNotifier extends StateNotifier<AsyncValue<List<Project>>> {
  final ProjectRepository _repository;
  final String? _orgId;
  final AuthState _authState;

  ProjectListNotifier(this._repository, this._orgId, this._authState)
    : super(const AsyncValue.loading()) {
    if (_orgId != null && _orgId.isNotEmpty) {
      loadProjects();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> loadProjects() async {
    if (_orgId == null || _orgId.isEmpty) return;
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getProjects(_orgId);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> createProject(String name, String description) async {
    if (_orgId == null || _authState.user == null) return false;
    try {
      final newProj = await _repository.createProject(
        orgId: _orgId,
        name: name,
        description: description,
        createdBy: _authState.user!.id,
      );
      final currentList = state.value ?? [];
      state = AsyncValue.data([newProj, ...currentList]);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateProject(Project project) async {
    try {
      final updated = await _repository.updateProject(project);
      final currentList = state.value ?? [];
      final newList = currentList
          .map((p) => p.id == updated.id ? updated : p)
          .toList();
      state = AsyncValue.data(newList);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteProject(String projectId) async {
    if (_authState.user == null || _authState.role == null) return false;
    try {
      await _repository.deleteProject(
        projectId: projectId,
        requestingUserId: _authState.user!.id,
        userRole: _authState.role!,
      );
      final currentList = state.value ?? [];
      final newList = currentList.where((p) => p.id != projectId).toList();
      state = AsyncValue.data(newList);
      return true;
    } catch (e) {
      // Re-throw so caller can display the exact exception message (e.g. PermissionException)
      rethrow;
    }
  }
}

final projectListProvider =
    StateNotifierProvider<ProjectListNotifier, AsyncValue<List<Project>>>((
      ref,
    ) {
      final repo = ref.watch(projectRepositoryProvider);
      final authState = ref.watch(authProvider);
      return ProjectListNotifier(repo, authState.orgId, authState);
    });

final projectDetailProvider = FutureProvider.family<Project, String>((
  ref,
  projectId,
) async {
  final repo = ref.watch(projectRepositoryProvider);
  return await repo.getProjectById(projectId);
});
