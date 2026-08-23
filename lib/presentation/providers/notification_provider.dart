import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/notification_item.dart';
import 'auth_provider.dart';
import 'core_providers.dart';

class NotificationsNotifier extends StateNotifier<AsyncValue<List<NotificationItem>>> {
  final NotificationRepositoryProvider _ref;

  NotificationsNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    final authState = _ref.watch(authProvider);
    final notifRepo = _ref.watch(notificationRepositoryProvider);

    if (authState.user == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final list = await notifRepo.getNotifications(authState.user!.id);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final notifRepo = _ref.watch(notificationRepositoryProvider);
    try {
      await notifRepo.markAsRead(notificationId);
      final currentList = state.value ?? [];
      final newList = currentList.map((n) {
        if (n.id == notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();
      state = AsyncValue.data(newList);
    } catch (_) {}
  }
}

typedef NotificationRepositoryProvider = Ref;

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, AsyncValue<List<NotificationItem>>>((ref) {
  return NotificationsNotifier(ref);
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifsState = ref.watch(notificationsProvider);
  return notifsState.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
