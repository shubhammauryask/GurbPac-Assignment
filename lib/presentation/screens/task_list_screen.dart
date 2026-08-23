import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/task.dart';
import '../providers/project_provider.dart';
import '../providers/task_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/error_state_view.dart';
import '../widgets/priority_chip.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/status_badge.dart';

class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return const TaskFilterBottomSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksState = ref.watch(taskListProvider);
    final filterState = ref.watch(taskFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list_rounded),
                onPressed: () => _showFilterSheet(context, ref),
              ),
              if (filterState.hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(taskListProvider.notifier).loadTasks();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'task_list_fab',
        onPressed: () {
          context.push('/tasks/new');
        },
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
      body: Column(
        children: [
          if (filterState.hasActiveFilters)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.primary.withOpacity(0.08),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Filters Applied',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(taskFilterProvider.notifier).clearAll();
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Clear All', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(taskListProvider.notifier).loadTasks();
              },
              child: tasksState.when(
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return EmptyStateView(
                      title: 'No Tasks Found',
                      message: filterState.hasActiveFilters
                          ? 'No tasks match the active filters. Try clearing filters.'
                          : 'Create your first task to get started.',
                      icon: Icons.check_box_outlined,
                      buttonText: filterState.hasActiveFilters ? 'Clear Filters' : 'New Task',
                      onButtonPressed: () {
                        if (filterState.hasActiveFilters) {
                          ref.read(taskFilterProvider.notifier).clearAll();
                        } else {
                          context.push('/tasks/new');
                        }
                      },
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: tasks.length,
                    itemBuilder: (ctx, i) {
                      final task = tasks[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            context.push('/tasks/${task.id}');
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        task.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert),
                                      onSelected: (val) async {
                                        if (val == 'edit') {
                                          context.push('/tasks/${task.id}/edit');
                                        } else if (val == 'delete') {
                                          final confirm = await ConfirmDialog.show(
                                            context,
                                            title: 'Delete Task',
                                            message: 'Are you sure you want to delete "${task.title}"?',
                                            confirmText: 'Delete',
                                            isDestructive: true,
                                          );
                                          if (confirm == true) {
                                            try {
                                              await ref.read(taskListProvider.notifier).deleteTask(task.id);
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
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Edit Task'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete Task', style: TextStyle(color: AppColors.error)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (task.description.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    task.description,
                                    style: const TextStyle(
                                      color: AppColors.darkTextSecondary,
                                      fontSize: 13,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    StatusBadge(status: task.status, compact: true),
                                    const SizedBox(width: 8),
                                    PriorityChip(priority: task.priority, compact: true),
                                    const Spacer(),
                                    if (task.dueDate != null)
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.darkTextSecondary),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.darkTextSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 5,
                  itemBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: SkeletonLoader(height: 110),
                  ),
                ),
                error: (err, _) => ErrorStateView(
                  message: err.toString(),
                  onRetry: () {
                    ref.read(taskListProvider.notifier).loadTasks();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TaskFilterBottomSheet extends ConsumerWidget {
  const TaskFilterBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(taskFilterProvider);
    final projectsState = ref.watch(projectListProvider);
    final usersAsync = ref.watch(orgMembersProvider);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Tasks',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Project Filter Dropdown
            const Text('Project', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String?>(
              value: filterState.projectId,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Projects')),
                ...(projectsState.value ?? []).map(
                  (p) => DropdownMenuItem(value: p.id, child: Text(p.name)),
                ),
              ],
              onChanged: (val) {
                ref.read(taskFilterProvider.notifier).setProjectId(val);
              },
            ),
            const SizedBox(height: 16),

            // Status Filter Dropdown
            const Text('Status', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            DropdownButtonFormField<TaskStatus?>(
              value: filterState.status,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Statuses')),
                ...TaskStatus.values.map(
                  (s) => DropdownMenuItem(value: s, child: Text(s.displayName)),
                ),
              ],
              onChanged: (val) {
                ref.read(taskFilterProvider.notifier).setStatus(val);
              },
            ),
            const SizedBox(height: 16),

            // Priority Filter Dropdown
            const Text('Priority', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            DropdownButtonFormField<TaskPriority?>(
              value: filterState.priority,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Priorities')),
                ...TaskPriority.values.map(
                  (p) => DropdownMenuItem(value: p, child: Text(p.displayName)),
                ),
              ],
              onChanged: (val) {
                ref.read(taskFilterProvider.notifier).setPriority(val);
              },
            ),
            const SizedBox(height: 16),

            // Assignee Filter Dropdown
            const Text('Assignee', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String?>(
              value: filterState.assigneeId,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Members')),
                const DropdownMenuItem(value: 'unassigned', child: Text('Unassigned')),
                ...(usersAsync.value ?? []).map(
                  (u) => DropdownMenuItem(value: u.id, child: Text(u.name)),
                ),
              ],
              onChanged: (val) {
                ref.read(taskFilterProvider.notifier).setAssigneeId(val);
              },
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(taskFilterProvider.notifier).clearAll();
                      Navigator.pop(context);
                    },
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
    );
  }
}

