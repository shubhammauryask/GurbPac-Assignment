import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/debug_options_manager.dart';
import '../../core/storage/local_storage_service.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../data/datasources/taskflow_mock_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../data/repositories/project_repository_impl.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/repositories/project_repository.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/repositories/user_repository.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized in main()');
});

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final localStorageProvider = Provider<LocalStorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalStorageService(prefs);
});

final debugOptionsProvider = ChangeNotifierProvider<DebugOptionsManagerNotifier>((ref) {
  return DebugOptionsManagerNotifier();
});

class DebugOptionsManagerNotifier extends DebugOptionsManager with ChangeNotifier {
  void updateDelay(int delayMs) {
    simulatedDelayMs = delayMs;
    notifyListeners();
  }

  void toggleForce404(bool val) {
    force404Error = val;
    notifyListeners();
  }

  void toggleForceTimeout(bool val) {
    forceTimeoutError = val;
    notifyListeners();
  }

  void toggleForceValidation(bool val) {
    forceValidationError = val;
    notifyListeners();
  }

  void toggleOffline(bool val) {
    isOffline = val;
    notifyListeners();
  }
}


final mockDataSourceProvider = Provider<TaskFlowMockDataSource>((ref) {
  final localStorage = ref.watch(localStorageProvider);
  final debugOptions = ref.watch(debugOptionsProvider);
  return TaskFlowMockDataSource(localStorage, debugOptions);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dataSource = ref.watch(mockDataSourceProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthRepositoryImpl(dataSource, secureStorage);
});

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final dataSource = ref.watch(mockDataSourceProvider);
  return ProjectRepositoryImpl(dataSource);
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final dataSource = ref.watch(mockDataSourceProvider);
  return TaskRepositoryImpl(dataSource);
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final dataSource = ref.watch(mockDataSourceProvider);
  return UserRepositoryImpl(dataSource);
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final dataSource = ref.watch(mockDataSourceProvider);
  return NotificationRepositoryImpl(dataSource);
});
