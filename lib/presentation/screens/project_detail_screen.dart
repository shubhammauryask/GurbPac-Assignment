import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/task.dart';
import '../providers/project_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/error_state_view.dart';
import '../widgets/priority_chip.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/status_badge.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectDetailProvider(projectId));
    final tasksAsync = ref.watch(taskListProvider);

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
        title: const Text('Project Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              context.push('/projects/$projectId/edit');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'project_detail_fab',
        onPressed: () {
          context.push('/tasks/new?projectId=$projectId');
        },
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Add Task'),
      ),
      body: projectAsync.when(
        data: (project) {
          final projectTasks =
              tasksAsync.value
                  ?.where((t) => t.projectId == projectId)
                  .toList() ??
              [];

          final todoCount = projectTasks
              .where((t) => t.status == TaskStatus.todo)
              .length;
          final inProgCount = projectTasks
              .where((t) => t.status == TaskStatus.inProgress)
              .length;
          final reviewCount = projectTasks
              .where((t) => t.status == TaskStatus.review)
              .length;
          final completedCount = projectTasks
              .where((t) => t.status == TaskStatus.completed)
              .length;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(projectDetailProvider(projectId));
              await ref.read(taskListProvider.notifier).loadTasks();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Project Header Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.folder_open_rounded,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      project.name,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ID: ${project.id}',
                                      style: const TextStyle(
                                        color: AppColors.darkTextSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (project.description.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              project.description,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.darkTextSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Task Breakdown Stats
                  const Text(
                    'Tasks Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildSummaryCard(
                        'To Do',
                        todoCount,
                        AppColors.statusTodo,
                      ),
                      const SizedBox(width: 8),
                      _buildSummaryCard(
                        'In Progress',
                        inProgCount,
                        AppColors.statusInProgress,
                      ),
                      const SizedBox(width: 8),
                      _buildSummaryCard(
                        'Review',
                        reviewCount,
                        AppColors.statusReview,
                      ),
                      const SizedBox(width: 8),
                      _buildSummaryCard(
                        'Completed',
                        completedCount,
                        AppColors.statusCompleted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // List of Tasks
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Project Tasks',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${projectTasks.length} tasks',
                        style: const TextStyle(
                          color: AppColors.darkTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (projectTasks.isEmpty)
                    EmptyStateView(
                      title: 'No Tasks Yet',
                      message:
                          'Add tasks to this project to start tracking work.',
                      icon: Icons.check_box_outlined,
                      buttonText: 'Add Task',
                      onButtonPressed: () =>
                          context.go('/tasks/new?projectId=$projectId'),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: projectTasks.length,
                      itemBuilder: (ctx, i) {
                        final task = projectTasks[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            onTap: () {
                              context.push('/tasks/${task.id}');
                            },
                            title: Text(
                              task.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Row(
                                children: [
                                  PriorityChip(
                                    priority: task.priority,
                                    compact: true,
                                  ),
                                  const SizedBox(width: 8),
                                  StatusBadge(
                                    status: task.status,
                                    compact: true,
                                  ),
                                ],
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right, size: 20),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: SkeletonLoader(height: 200),
          ),
        ),
        error: (err, _) => ErrorStateView(
          message: err.toString(),
          onRetry: () {
            ref.invalidate(projectDetailProvider(projectId));
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
