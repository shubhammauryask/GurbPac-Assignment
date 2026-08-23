import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/task.dart';
import '../providers/auth_provider.dart';
import '../providers/core_providers.dart';
import '../providers/task_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/error_state_view.dart';
import '../widgets/priority_chip.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/status_badge.dart';
import '../widgets/user_avatar.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final _commentController = TextEditingController();
  bool _isAddingComment = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final authState = ref.read(authProvider);
    if (authState.user == null) return;

    setState(() {
      _isAddingComment = true;
    });

    try {
      await ref
          .read(taskRepositoryProvider)
          .addComment(
            taskId: widget.taskId,
            userId: authState.user!.id,
            content: text,
          );
      _commentController.clear();
      ref.invalidate(taskCommentsProvider(widget.taskId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingComment = false;
        });
      }
    }
  }

  void _showAssigneePicker(TaskItem task) {
    final usersAsync = ref.read(orgMembersProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Assign Member',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.darkSurfaceVariant,
                  child: Icon(Icons.person_off_outlined, color: Colors.white),
                ),
                title: const Text('Unassigned'),
                trailing: task.assigneeId == null
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  await _updateAssignee(null);
                },
              ),
              const Divider(),
              usersAsync.when(
                data: (users) => Expanded(
                  child: ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final u = users[index];
                      final isCurrent = task.assigneeId == u.id;
                      return ListTile(
                        leading: UserAvatar(
                          name: u.name,
                          avatarUrl: u.avatarUrl,
                        ),
                        title: Text(u.name),
                        subtitle: Text(u.email),
                        trailing: isCurrent
                            ? const Icon(Icons.check, color: AppColors.primary)
                            : null,
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _updateAssignee(u.id);
                        },
                      );
                    },
                  ),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => Text('Error: $err'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateAssignee(String? newAssigneeId) async {
    try {
      await ref
          .read(taskListProvider.notifier)
          .assignTaskUser(widget.taskId, newAssigneeId);
      ref.invalidate(taskDetailProvider(widget.taskId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task assignment updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskAsync = ref.watch(taskDetailProvider(widget.taskId));
    final commentsAsync = ref.watch(taskCommentsProvider(widget.taskId));
    final orgMembersAsync = ref.watch(orgMembersProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: const Text('Task Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              context.push('/tasks/${widget.taskId}/edit');
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
            ),
            onPressed: () async {
              final confirm = await ConfirmDialog.show(
                context,
                title: 'Delete Task',
                message: 'Are you sure you want to delete this task?',
                confirmText: 'Delete',
                isDestructive: true,
              );
              if (confirm == true) {
                try {
                  await ref
                      .read(taskListProvider.notifier)
                      .deleteTask(widget.taskId);
                  if (context.mounted) {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/dashboard');
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: taskAsync.when(
        data: (task) {
          final assigneeUser = (orgMembersAsync.value ?? [])
              .where((u) => u.id == task.assigneeId)
              .firstOrNull;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(taskDetailProvider(widget.taskId));
              ref.invalidate(taskCommentsProvider(widget.taskId));
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status & Priority Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StatusBadge(status: task.status),
                      PriorityChip(priority: task.priority),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            task.description.isEmpty
                                ? 'No description provided.'
                                : task.description,
                            style: const TextStyle(fontSize: 14, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick Status Change Popover
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.sync_alt_rounded,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Update Status:',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          DropdownButton<TaskStatus>(
                            value: task.status,
                            underline: const SizedBox.shrink(),
                            items: TaskStatus.values
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s.displayName),
                                  ),
                                )
                                .toList(),
                            onChanged: (newStatus) async {
                              if (newStatus != null) {
                                try {
                                  await ref
                                      .read(taskListProvider.notifier)
                                      .updateTaskStatus(task.id, newStatus);
                                  ref.invalidate(
                                    taskDetailProvider(widget.taskId),
                                  );
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(e.toString()),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Assignee Selector Card
                  Card(
                    child: ListTile(
                      onTap: () => _showAssigneePicker(task),
                      leading: assigneeUser != null
                          ? UserAvatar(
                              name: assigneeUser.name,
                              avatarUrl: assigneeUser.avatarUrl,
                            )
                          : const CircleAvatar(
                              backgroundColor: AppColors.darkSurfaceVariant,
                              child: Icon(
                                Icons.person_add_alt_1,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                      title: const Text(
                        'Assignee',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.darkTextSecondary,
                        ),
                      ),
                      subtitle: Text(
                        assigneeUser != null
                            ? assigneeUser.name
                            : 'Unassigned (Tap to assign)',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Comments Thread
                  const Text(
                    'Comments & Activity',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  commentsAsync.when(
                    data: (comments) {
                      if (comments.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            'No comments yet. Be the first to start the discussion!',
                            style: TextStyle(
                              color: AppColors.darkTextSecondary,
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (ctx, i) {
                          final comment = comments[i];
                          final author = (orgMembersAsync.value ?? [])
                              .where((u) => u.id == comment.userId)
                              .firstOrNull;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  UserAvatar(
                                    name: author?.name ?? 'User',
                                    avatarUrl: author?.avatarUrl,
                                    radius: 14,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              author?.name ?? 'User',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              '${comment.createdAt.hour}:${comment.createdAt.minute.toString().padLeft(2, '0')}',
                                              style: const TextStyle(
                                                color:
                                                    AppColors.darkTextSecondary,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          comment.content,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const SkeletonLoader(height: 80),
                    error: (err, _) => Text('Error loading comments: $err'),
                  ),
                  const SizedBox(height: 16),

                  // Add Comment Input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            hintText: 'Add a comment...',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _isAddingComment ? null : _postComment,
                        icon: _isAddingComment
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorStateView(
          message: err.toString(),
          onRetry: () {
            ref.invalidate(taskDetailProvider(widget.taskId));
          },
        ),
      ),
    );
  }
}
