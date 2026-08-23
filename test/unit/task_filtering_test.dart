import 'package:flutter_test/flutter_test.dart';
import 'package:task_flow/core/network/debug_options_manager.dart';
import 'package:task_flow/core/storage/local_storage_service.dart';
import 'package:task_flow/data/datasources/taskflow_mock_datasource.dart';
import 'package:task_flow/data/repositories/task_repository_impl.dart';
import 'package:task_flow/domain/entities/task.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TaskFlowMockDataSource dataSource;
  late TaskRepositoryImpl taskRepository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final localStorage = LocalStorageService(prefs);
    final debugOpts = DebugOptionsManager(simulatedDelayMs: 0);
    dataSource = TaskFlowMockDataSource(localStorage, debugOpts);
    taskRepository = TaskRepositoryImpl(dataSource);
  });

  group('Task Filtering Unit Tests', () {
    test('Filter tasks by status returns matching tasks', () async {
      final tasks = await taskRepository.getTasks(
        orgId: 'org-1',
        status: TaskStatus.inProgress,
      );

      expect(tasks, isNotEmpty);
      for (final t in tasks) {
        expect(t.status, equals(TaskStatus.inProgress));
      }
    });

    test('Filter tasks by priority returns matching tasks', () async {
      final tasks = await taskRepository.getTasks(
        orgId: 'org-1',
        priority: TaskPriority.urgent,
      );

      expect(tasks, isNotEmpty);
      for (final t in tasks) {
        expect(t.priority, equals(TaskPriority.urgent));
      }
    });

    test('Filter tasks by project_id returns project-scoped tasks', () async {
      final tasks = await taskRepository.getTasks(
        orgId: 'org-1',
        projectId: 'proj-1',
      );

      expect(tasks, isNotEmpty);
      for (final t in tasks) {
        expect(t.projectId, equals('proj-1'));
      }
    });
  });
}
