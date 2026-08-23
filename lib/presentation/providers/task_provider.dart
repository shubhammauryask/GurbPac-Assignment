import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import 'auth_provider.dart';
import 'core_providers.dart';

class TaskFilterState extends Equatable {
  final String? projectId;
  final TaskStatus? status;
  final TaskPriority? priority;
  final String? assigneeId;
  final DateTimeRange? dateRange;

  const TaskFilterState({
    this.projectId,
    this.status,
    this.priority,
    this.assigneeId,
    this.dateRange,
  });

  bool get hasActiveFilters =>
      projectId != null ||
      status != null ||
      priority != null ||
      assigneeId != null ||
      dateRange != null;

  TaskFilterState copyWith({
    String? Function()? projectId,
    TaskStatus? Function()? status,
    TaskPriority? Function()? priority,
    String? Function()? assigneeId,
    DateTimeRange? Function()? dateRange,
  }) {
    return TaskFilterState(
      projectId: projectId != null ? projectId() : this.projectId,
      status: status != null ? status() : this.status,
      priority: priority != null ? priority() : this.priority,
      assigneeId: assigneeId != null ? assigneeId() : this.assigneeId,
      dateRange: dateRange != null ? dateRange() : this.dateRange,
    );
  }

  @override
  List<Object?> get props => [projectId, status, priority, assigneeId, dateRange];
}

class TaskFilterNotifier extends StateNotifier<TaskFilterState> {
  TaskFilterNotifier() : super(const TaskFilterState());

  void setProjectId(String? projId) {
    state = state.copyWith(projectId: () => projId);
  }

  void setStatus(TaskStatus? status) {
    state = state.copyWith(status: () => status);
  }

  void setPriority(TaskPriority? priority) {
    state = state.copyWith(priority: () => priority);
  }

  void setAssigneeId(String? assigneeId) {
    state = state.copyWith(assigneeId: () => assigneeId);
  }

  void setDateRange(DateTimeRange? range) {
    state = state.copyWith(dateRange: () => range);
  }

  void clearAll() {
    state = const TaskFilterState();
  }
}

final taskFilterProvider =
    StateNotifierProvider<TaskFilterNotifier, TaskFilterState>((ref) {
  return TaskFilterNotifier();
});

class TaskListNotifier extends StateNotifier<AsyncValue<List<TaskItem>>> {
  final TaskRepository _repository;
  final String? _orgId;
  final TaskFilterState _filter;

  TaskListNotifier(this._repository, this._orgId, this._filter)
      : super(const AsyncValue.loading()) {
    if (_orgId != null && _orgId.isNotEmpty) {
      loadTasks();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> loadTasks() async {
    if (_orgId == null || _orgId.isEmpty) return;
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getTasks(
        orgId: _orgId,
        projectId: _filter.projectId,
        status: _filter.status,
        priority: _filter.priority,
        assigneeId: _filter.assigneeId,
        dateRange: _filter.dateRange,
      );
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> createTask(TaskItem task) async {
    try {
      final created = await _repository.createTask(task);
      final currentList = state.value ?? [];
      state = AsyncValue.data([created, ...currentList]);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateTask(TaskItem task) async {
    try {
      final updated = await _repository.updateTask(task);
      final currentList = state.value ?? [];
      final newList = currentList.map((t) => t.id == updated.id ? updated : t).toList();
      state = AsyncValue.data(newList);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateTaskStatus(String taskId, TaskStatus status) async {
    final currentList = state.value ?? [];
    final existing = currentList.where((t) => t.id == taskId).firstOrNull;
    if (existing == null) return false;
    final updated = existing.copyWith(status: status, updatedAt: DateTime.now());
    return await updateTask(updated);
  }

  Future<bool> assignTaskUser(String taskId, String? assigneeId) async {
    if (_orgId == null) return false;
    try {
      final updated = await _repository.assignTask(
        taskId: taskId,
        assigneeId: assigneeId,
        requestingOrgId: _orgId,
      );
      final currentList = state.value ?? [];
      final newList = currentList.map((t) => t.id == updated.id ? updated : t).toList();
      state = AsyncValue.data(newList);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteTask(String taskId) async {
    try {
      await _repository.deleteTask(taskId);
      final currentList = state.value ?? [];
      final newList = currentList.where((t) => t.id != taskId).toList();
      state = AsyncValue.data(newList);
      return true;
    } catch (e) {
      rethrow;
    }
  }
}

final taskListProvider =
    StateNotifierProvider<TaskListNotifier, AsyncValue<List<TaskItem>>>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  final authState = ref.watch(authProvider);
  final filter = ref.watch(taskFilterProvider);
  return TaskListNotifier(repo, authState.orgId, filter);
});

final taskDetailProvider =
    FutureProvider.family<TaskItem, String>((ref, taskId) async {
  final repo = ref.watch(taskRepositoryProvider);
  return await repo.getTaskById(taskId);
});

final taskCommentsProvider =
    FutureProvider.family<List<Comment>, String>((ref, taskId) async {
  final repo = ref.watch(taskRepositoryProvider);
  return await repo.getComments(taskId);
});
