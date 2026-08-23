import 'package:flutter/material.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/taskflow_mock_datasource.dart';
import '../models/comment_model.dart';
import '../models/notification_model.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskFlowMockDataSource _dataSource;

  TaskRepositoryImpl(this._dataSource);

  @override
  Future<List<TaskItem>> getTasks({
    required String orgId,
    String? projectId,
    TaskStatus? status,
    TaskPriority? priority,
    String? assigneeId,
    DateTimeRange? dateRange,
  }) async {
    await _dataSource.init();

    var list = await _dataSource.getTasks(orgId);

    if (projectId != null && projectId.isNotEmpty) {
      list = list.where((t) => t.projectId == projectId).toList();
    }
    if (status != null) {
      list = list.where((t) => t.status == status).toList();
    }
    if (priority != null) {
      list = list.where((t) => t.priority == priority).toList();
    }
    if (assigneeId != null && assigneeId.isNotEmpty) {
      if (assigneeId == 'unassigned') {
        list = list.where((t) => t.assigneeId == null).toList();
      } else {
        list = list.where((t) => t.assigneeId == assigneeId).toList();
      }
    }
    if (dateRange != null) {
      list = list.where((t) {
        if (t.dueDate == null) return false;
        return t.dueDate!.isAfter(dateRange.start) &&
            t.dueDate!.isBefore(dateRange.end.add(const Duration(days: 1)));
      }).toList();
    }

    return list;
  }

  @override
  Future<TaskItem> getTaskById(String taskId) async {
    await _dataSource.init();
    return await _dataSource.getTaskById(taskId);
  }

  @override
  Future<TaskItem> createTask(TaskItem task) async {
    await _dataSource.init();

    if (task.title.trim().isEmpty) {
      throw const ValidationException('Task title cannot be empty', code: 'EMPTY_TITLE');
    }

    // If an assignee is provided, validate org membership
    if (task.assigneeId != null && task.assigneeId!.isNotEmpty) {
      final member = await _dataSource.getOrgMember(task.orgId, task.assigneeId!);
      if (member == null) {
        throw const ValidationException(
          'Cannot assign task: Selected user does not belong to this organization.',
          code: 'CROSS_ORG_ASSIGNMENT_FORBIDDEN',
        );
      }
    }

    final model = TaskModel(
      id: task.id.isNotEmpty ? task.id : 'task-${DateTime.now().millisecondsSinceEpoch}',
      projectId: task.projectId,
      orgId: task.orgId,
      title: task.title.trim(),
      description: task.description.trim(),
      status: task.status,
      priority: task.priority,
      assigneeId: task.assigneeId,
      createdBy: task.createdBy,
      dueDate: task.dueDate,
      createdAt: task.createdAt,
      updatedAt: DateTime.now(),
    );

    final created = await _dataSource.createTask(model);

    // If assigned, create a notification
    if (created.assigneeId != null && created.assigneeId!.isNotEmpty) {
      _dataSource.addNotification(
        NotificationModel(
          id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
          userId: created.assigneeId!,
          taskId: created.id,
          title: 'New Task Assignment',
          message: 'You have been assigned to task "${created.title}".',
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );
    }

    return created;
  }

  @override
  Future<TaskItem> updateTask(TaskItem task) async {
    await _dataSource.init();

    if (task.title.trim().isEmpty) {
      throw const ValidationException('Task title cannot be empty', code: 'EMPTY_TITLE');
    }

    // Validate org membership for assignee
    if (task.assigneeId != null && task.assigneeId!.isNotEmpty) {
      final member = await _dataSource.getOrgMember(task.orgId, task.assigneeId!);
      if (member == null) {
        throw const ValidationException(
          'Cannot assign task: Selected user does not belong to this organization.',
          code: 'CROSS_ORG_ASSIGNMENT_FORBIDDEN',
        );
      }
    }

    final model = TaskModel(
      id: task.id,
      projectId: task.projectId,
      orgId: task.orgId,
      title: task.title.trim(),
      description: task.description.trim(),
      status: task.status,
      priority: task.priority,
      assigneeId: task.assigneeId,
      createdBy: task.createdBy,
      dueDate: task.dueDate,
      createdAt: task.createdAt,
      updatedAt: DateTime.now(),
    );

    return await _dataSource.updateTask(model);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await _dataSource.init();
    await _dataSource.deleteTask(taskId);
  }

  @override
  Future<TaskItem> assignTask({
    required String taskId,
    String? assigneeId,
    required String requestingOrgId,
  }) async {
    await _dataSource.init();

    final task = await _dataSource.getTaskById(taskId);

    if (assigneeId != null && assigneeId.isNotEmpty) {
      final member = await _dataSource.getOrgMember(requestingOrgId, assigneeId);
      if (member == null) {
        throw const ValidationException(
          '400 Bad Request: Cannot assign user to task because they do not belong to the active organization.',
          code: 'CROSS_ORG_ASSIGNMENT_FORBIDDEN',
        );
      }
    }

    final updatedTask = task.copyWith(
      assigneeId: () => assigneeId,
      updatedAt: DateTime.now(),
    );

    final model = TaskModel(
      id: updatedTask.id,
      projectId: updatedTask.projectId,
      orgId: updatedTask.orgId,
      title: updatedTask.title,
      description: updatedTask.description,
      status: updatedTask.status,
      priority: updatedTask.priority,
      assigneeId: updatedTask.assigneeId,
      createdBy: updatedTask.createdBy,
      dueDate: updatedTask.dueDate,
      createdAt: updatedTask.createdAt,
      updatedAt: updatedTask.updatedAt,
    );

    final saved = await _dataSource.updateTask(model);

    if (assigneeId != null && assigneeId.isNotEmpty) {
      _dataSource.addNotification(
        NotificationModel(
          id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
          userId: assigneeId,
          taskId: saved.id,
          title: 'Assigned to Task',
          message: 'You were assigned to "${saved.title}".',
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );
    }

    return saved;
  }

  @override
  Future<List<Comment>> getComments(String taskId) async {
    await _dataSource.init();
    return await _dataSource.getComments(taskId);
  }

  @override
  Future<Comment> addComment({
    required String taskId,
    required String userId,
    required String content,
  }) async {
    await _dataSource.init();

    if (content.trim().isEmpty) {
      throw const ValidationException('Comment cannot be empty', code: 'EMPTY_COMMENT');
    }

    final commentModel = CommentModel(
      id: 'cmt-${DateTime.now().millisecondsSinceEpoch}',
      taskId: taskId,
      userId: userId,
      content: content.trim(),
      createdAt: DateTime.now(),
    );

    return await _dataSource.addComment(commentModel);
  }
}
