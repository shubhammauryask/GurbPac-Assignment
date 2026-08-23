import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/org_member.dart';
import '../providers/auth_provider.dart';
import '../providers/project_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/error_state_view.dart';
import '../widgets/skeleton_loader.dart';

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsState = ref.watch(projectListProvider);
    final tasksState = ref.watch(taskListProvider);
    final authState = ref.watch(authProvider);

    final isAdmin = authState.role == OrgRole.orgAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(projectListProvider.notifier).loadProjects();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'project_list_fab',
        onPressed: () {
          context.push('/projects/new');
        },
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(projectListProvider.notifier).loadProjects();
        },
        child: projectsState.when(
          data: (projects) {
            if (projects.isEmpty) {
              return EmptyStateView(
                title: 'No Projects Found',
                message:
                    'Create a project to start organizing tasks in your organization.',
                icon: Icons.folder_outlined,
                buttonText: 'Create Project',
                onButtonPressed: () => context.push('/projects/new'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: projects.length,
              itemBuilder: (ctx, index) {
                final project = projects[index];
                final projectTasks =
                    tasksState.value
                        ?.where((t) => t.projectId == project.id)
                        .toList() ??
                    [];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      context.push('/projects/${project.id}');
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.folder_special_rounded,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      project.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      project.description,
                                      style: const TextStyle(
                                        color: AppColors.darkTextSecondary,
                                        fontSize: 13,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (val) async {
                                  if (val == 'edit') {
                                    context.push(
                                      '/projects/${project.id}/edit',
                                    );
                                  } else if (val == 'delete') {
                                    final confirm = await ConfirmDialog.show(
                                      context,
                                      title: 'Delete Project',
                                      message:
                                          'Are you sure you want to delete "${project.name}"? This action cannot be undone.',
                                      confirmText: 'Delete',
                                      isDestructive: true,
                                    );
                                    if (confirm == true) {
                                      try {
                                        await ref
                                            .read(projectListProvider.notifier)
                                            .deleteProject(project.id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Project deleted successfully',
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
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
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined, size: 18),
                                        SizedBox(width: 8),
                                        Text('Edit Project'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_outline_rounded,
                                          size: 18,
                                          color: isAdmin
                                              ? AppColors.error
                                              : AppColors.darkTextSecondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Delete Project',
                                          style: TextStyle(
                                            color: isAdmin
                                                ? AppColors.error
                                                : AppColors.darkTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.check_box_outlined,
                                    size: 16,
                                    color: AppColors.darkTextSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${projectTasks.length} tasks',
                                    style: const TextStyle(
                                      color: AppColors.darkTextSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const Row(
                                children: [
                                  Text(
                                    'View Details',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 12,
                                    color: AppColors.primary,
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
            itemCount: 4,
            itemBuilder: (_, __) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: SkeletonLoader(height: 120),
            ),
          ),
          error: (err, _) => ErrorStateView(
            message: err.toString(),
            onRetry: () {
              ref.read(projectListProvider.notifier).loadProjects();
            },
          ),
        ),
      ),
    );
  }
}
