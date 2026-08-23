import 'package:equatable/equatable.dart';

enum TaskStatus {
  todo,
  inProgress,
  review,
  completed;

  String get value {
    switch (this) {
      case TaskStatus.todo:
        return 'todo';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.review:
        return 'review';
      case TaskStatus.completed:
        return 'completed';
    }
  }

  static TaskStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'in_progress':
      case 'inprogress':
        return TaskStatus.inProgress;
      case 'review':
        return TaskStatus.review;
      case 'completed':
      case 'done':
        return TaskStatus.completed;
      case 'todo':
      default:
        return TaskStatus.todo;
    }
  }

  String get displayName {
    switch (this) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.review:
        return 'In Review';
      case TaskStatus.completed:
        return 'Completed';
    }
  }
}

enum TaskPriority {
  low,
  medium,
  high,
  urgent;

  String get value {
    switch (this) {
      case TaskPriority.low:
        return 'low';
      case TaskPriority.medium:
        return 'medium';
      case TaskPriority.high:
        return 'high';
      case TaskPriority.urgent:
        return 'urgent';
    }
  }

  static TaskPriority fromString(String val) {
    switch (val.toLowerCase()) {
      case 'urgent':
        return TaskPriority.urgent;
      case 'high':
        return TaskPriority.high;
      case TaskPriority.medium:
        return TaskPriority.medium;
      case TaskPriority.low:
      default:
        return TaskPriority.low;
    }
  }

  String get displayName {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }
}

class TaskItem extends Equatable {
  final String id;
  final String projectId;
  final String orgId;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final String? assigneeId;
  final String createdBy;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskItem({
    required this.id,
    required this.projectId,
    required this.orgId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.assigneeId,
    required this.createdBy,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  TaskItem copyWith({
    String? id,
    String? projectId,
    String? orgId,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    String? Function()? assigneeId,
    String? createdBy,
    DateTime? Function()? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskItem(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      orgId: orgId ?? this.orgId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assigneeId: assigneeId != null ? assigneeId() : this.assigneeId,
      createdBy: createdBy ?? this.createdBy,
      dueDate: dueDate != null ? dueDate() : this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        orgId,
        title,
        description,
        status,
        priority,
        assigneeId,
        createdBy,
        dueDate,
        createdAt,
        updatedAt,
      ];
}
