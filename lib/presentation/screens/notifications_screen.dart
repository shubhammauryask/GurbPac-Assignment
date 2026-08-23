import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../providers/notification_provider.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/error_state_view.dart';
import '../widgets/skeleton_loader.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsState = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications Inbox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(notificationsProvider.notifier).loadNotifications();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(notificationsProvider.notifier).loadNotifications();
        },
        child: notifsState.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return const EmptyStateView(
                title: 'Inbox Empty',
                message: 'You have no notifications or assignment alerts at the moment.',
                icon: Icons.notifications_none_rounded,
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: notifications.length,
              itemBuilder: (ctx, i) {
                final notif = notifications[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: notif.isRead
                      ? null
                      : AppColors.primary.withOpacity(0.08),
                  child: ListTile(
                    onTap: () {
                      ref.read(notificationsProvider.notifier).markAsRead(notif.id);
                      context.push('/tasks/${notif.taskId}');
                    },
                    leading: CircleAvatar(
                      backgroundColor: notif.isRead
                          ? AppColors.darkSurfaceVariant
                          : AppColors.primary,
                      child: Icon(
                        notif.isRead
                            ? Icons.notifications_outlined
                            : Icons.assignment_ind_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              fontWeight: notif.isRead
                                  ? FontWeight.w600
                                  : FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (!notif.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        notif.message,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                  ),
                );
              },
            );
          },
          loading: () => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 4,
            itemBuilder: (_, __) => const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: SkeletonLoader(height: 70),
            ),
          ),
          error: (err, _) => ErrorStateView(
            message: err.toString(),
            onRetry: () {
              ref.read(notificationsProvider.notifier).loadNotifications();
            },
          ),
        ),
      ),
    );
  }
}
