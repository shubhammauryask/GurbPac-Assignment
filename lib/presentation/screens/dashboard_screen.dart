import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/org_member.dart';
import '../../domain/entities/task.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/project_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/offline_banner.dart';
import '../widgets/priority_chip.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/status_badge.dart';
import 'notifications_screen.dart';
import 'profile_settings_screen.dart';
import 'project_list_screen.dart';
import 'task_list_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: const [
                HomeDashboardTab(),
                ProjectListScreen(),
                TaskListScreen(),
                NotificationsScreen(),
                ProfileSettingsScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder_rounded),
            label: 'Projects',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.check_box_outlined),
            activeIcon: Icon(Icons.check_box_rounded),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined),
                if (unreadCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            activeIcon: const Icon(Icons.notifications_rounded),
            label: 'Inbox',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class HomeDashboardTab extends ConsumerWidget {
  const HomeDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final projectsState = ref.watch(projectListProvider);
    final tasksState = ref.watch(taskListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.task_alt_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'TaskFlow',
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              authState.role == OrgRole.orgAdmin ? 'ORG ADMIN' : 'MEMBER',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(projectListProvider.notifier).loadProjects();
          await ref.read(taskListProvider.notifier).loadTasks();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${authState.user?.name ?? 'User'} 👋',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Org ID: ${authState.orgId ?? ''}',
                              style: const TextStyle(
                                color: AppColors.darkTextSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          (authState.user?.name ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Task Metrics Summary Cards
              const Text(
                'Task Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              tasksState.when(
                data: (tasks) {
                  final todoCount = tasks
                      .where((t) => t.status == TaskStatus.todo)
                      .length;
                  final inProgCount = tasks
                      .where((t) => t.status == TaskStatus.inProgress)
                      .length;
                  final reviewCount = tasks
                      .where((t) => t.status == TaskStatus.review)
                      .length;
                  final completedCount = tasks
                      .where((t) => t.status == TaskStatus.completed)
                      .length;

                  return Row(
                    children: [
                      _buildMetricTile(
                        'To Do',
                        todoCount,
                        AppColors.statusTodo,
                      ),
                      const SizedBox(width: 8),
                      _buildMetricTile(
                        'In Progress',
                        inProgCount,
                        AppColors.statusInProgress,
                      ),
                      const SizedBox(width: 8),
                      _buildMetricTile(
                        'Review',
                        reviewCount,
                        AppColors.statusReview,
                      ),
                      const SizedBox(width: 8),
                      _buildMetricTile(
                        'Done',
                        completedCount,
                        AppColors.statusCompleted,
                      ),
                    ],
                  );
                },
                loading: () => const Row(
                  children: [
                    Expanded(child: SkeletonLoader(height: 70)),
                    SizedBox(width: 8),
                    Expanded(child: SkeletonLoader(height: 70)),
                  ],
                ),
                error: (err, _) => Text(
                  'Error loading metrics: $err',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
              const SizedBox(height: 24),

              // Projects Overview Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Active Projects',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${projectsState.value?.length ?? 0} Total',
                    style: const TextStyle(color: AppColors.darkTextSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              projectsState.when(
                data: (projects) {
                  if (projects.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(
                          child: Text(
                            'No projects found in this organization.',
                          ),
                        ),
                      ),
                    );
                  }
                  return SizedBox(
                    height: 130,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: projects.length,
                      itemBuilder: (ctx, i) {
                        final proj = projects[i];
                        final projTasks =
                            tasksState.value
                                ?.where((t) => t.projectId == proj.id)
                                .toList() ??
                            [];
                        return Container(
                          width: 220,
                          margin: const EdgeInsets.only(right: 12),
                          child: Card(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                context.push('/projects/${proj.id}');
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      proj.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      proj.description,
                                      style: const TextStyle(
                                        color: AppColors.darkTextSecondary,
                                        fontSize: 12,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.task,
                                          size: 14,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${projTasks.length} tasks',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const SkeletonLoader(height: 120),
                error: (err, _) => Text('Error: $err'),
              ),
              const SizedBox(height: 24),

              // Urgent / Recent Tasks
              const Text(
                'Recent Tasks',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              tasksState.when(
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(child: Text('No tasks found.')),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tasks.length > 4 ? 4 : tasks.length,
                    itemBuilder: (ctx, i) {
                      final task = tasks[i];
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
                              fontSize: 14,
                            ),
                          ),

                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              children: [
                                PriorityChip(
                                  priority: task.priority,
                                  compact: true,
                                ),
                                const SizedBox(width: 8),
                                StatusBadge(status: task.status, compact: true),
                              ],
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Column(
                  children: [
                    SkeletonLoader(height: 60),
                    SizedBox(height: 8),
                    SkeletonLoader(height: 60),
                  ],
                ),
                error: (err, _) => Text('Error: $err'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
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
