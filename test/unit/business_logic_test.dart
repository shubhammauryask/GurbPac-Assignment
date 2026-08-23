import 'package:flutter_test/flutter_test.dart';
import 'package:task_flow/core/errors/failures.dart';
import 'package:task_flow/core/network/debug_options_manager.dart';
import 'package:task_flow/core/storage/local_storage_service.dart';
import 'package:task_flow/data/datasources/taskflow_mock_datasource.dart';
import 'package:task_flow/data/repositories/project_repository_impl.dart';
import 'package:task_flow/data/repositories/task_repository_impl.dart';
import 'package:task_flow/domain/entities/org_member.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TaskFlowMockDataSource dataSource;
  late ProjectRepositoryImpl projectRepo;
  late TaskRepositoryImpl taskRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final localStorage = LocalStorageService(prefs);
    final debugOpts = DebugOptionsManager(simulatedDelayMs: 0);
    dataSource = TaskFlowMockDataSource(localStorage, debugOpts);
    projectRepo = ProjectRepositoryImpl(dataSource);
    taskRepo = TaskRepositoryImpl(dataSource);
  });

  group('Business Logic & Validation Guard Unit Tests', () {
    test('Non-admin member cannot delete a project (throws PermissionException)', () async {
      expect(
        () async => await projectRepo.deleteProject(
          projectId: 'proj-1',
          requestingUserId: 'usr-2',
          userRole: OrgRole.member,
        ),
        throwsA(isA<PermissionException>()),
      );
    });

    test('Org admin can delete a project', () async {
      await projectRepo.deleteProject(
        projectId: 'proj-2',
        requestingUserId: 'usr-1',
        userRole: OrgRole.orgAdmin,
      );

      expect(
        () async => await projectRepo.getProjectById('proj-2'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('Assigning user from Org B to Org A task throws ValidationException', () async {
      expect(
        () async => await taskRepo.assignTask(
          taskId: 'task-101',
          assigneeId: 'usr-3', // usr-3 is in Org B
          requestingOrgId: 'org-1',
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
