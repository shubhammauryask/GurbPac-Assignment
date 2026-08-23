import '../../domain/entities/notification_item.dart';

class NotificationModel extends NotificationItem {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.taskId,
    required super.title,
    required super.message,
    required super.isRead,
    required super.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      taskId: json['task_id'] as String,
      title: (json['title'] ?? json['type'] ?? 'Notification') as String,
      message: json['message'] as String,
      isRead: (json['read'] ?? json['is_read']) as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'task_id': taskId,
      'title': title,
      'type': title,
      'message': message,
      'read': isRead,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
