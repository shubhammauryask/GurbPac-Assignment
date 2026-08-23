import '../../domain/entities/task.dart';

class TaskModel extends TaskItem {
  const TaskModel({
    required super.id,
    required super.projectId,
    required super.orgId,
    required super.title,
    required super.description,
    required super.status,
    required super.priority,
    super.assigneeId,
    required super.createdBy,
    super.dueDate,
    required super.createdAt,
    required super.updatedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      orgId: json['org_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      status: TaskStatus.fromString(json['status'] as String? ?? 'todo'),
      priority: TaskPriority.fromString(json['priority'] as String? ?? 'low'),
      assigneeId: json['assignee_id'] as String?,
      createdBy: json['created_by'] as String,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'org_id': orgId,
      'title': title,
      'description': description,
      'status': status.value,
      'priority': priority.value,
      'assignee_id': assigneeId,
      'created_by': createdBy,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
