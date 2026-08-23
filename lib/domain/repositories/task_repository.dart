import 'package:flutter/material.dart';
import '../entities/comment.dart';
import '../entities/task.dart';

abstract class TaskRepository {
  Future<List<TaskItem>> getTasks({
    required String orgId,
    String? projectId,
    TaskStatus? status,
    TaskPriority? priority,
    String? assigneeId,
    DateTimeRange? dateRange,
  });

  Future<TaskItem> getTaskById(String taskId);

  Future<TaskItem> createTask(TaskItem task);

  Future<TaskItem> updateTask(TaskItem task);

  Future<void> deleteTask(String taskId);

  Future<TaskItem> assignTask({
    required String taskId,
    String? assigneeId,
    required String requestingOrgId,
  });

  Future<List<Comment>> getComments(String taskId);

  Future<Comment> addComment({
    required String taskId,
    required String userId,
    required String content,
  });
}
