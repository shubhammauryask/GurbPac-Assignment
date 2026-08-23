import '../../domain/entities/comment.dart';

class CommentModel extends Comment {
  const CommentModel({
    required super.id,
    required super.taskId,
    required super.userId,
    required super.content,
    required super.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      userId: (json['author_id'] ?? json['user_id']) as String,
      content: (json['body'] ?? json['content']) as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'author_id': userId,
      'user_id': userId,
      'body': content,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
