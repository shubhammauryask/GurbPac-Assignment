import 'package:equatable/equatable.dart';

class NotificationItem extends Equatable {
  final String id;
  final String userId;
  final String taskId;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.userId,
    required this.taskId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  NotificationItem copyWith({
    String? id,
    String? userId,
    String? taskId,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, taskId, title, message, isRead, createdAt];
}
