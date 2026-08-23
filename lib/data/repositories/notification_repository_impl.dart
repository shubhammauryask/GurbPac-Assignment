import '../../domain/entities/notification_item.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/taskflow_mock_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final TaskFlowMockDataSource _dataSource;

  NotificationRepositoryImpl(this._dataSource);

  @override
  Future<List<NotificationItem>> getNotifications(String userId) async {
    await _dataSource.init();
    return await _dataSource.getNotifications(userId);
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _dataSource.init();
    await _dataSource.markNotificationAsRead(notificationId);
  }
}
