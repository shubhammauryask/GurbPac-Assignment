import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../core/errors/failures.dart';
import '../../core/network/debug_options_manager.dart';
import '../../core/storage/local_storage_service.dart';
import '../models/comment_model.dart';
import '../models/notification_model.dart';
import '../models/org_member_model.dart';
import '../models/organization_model.dart';
import '../models/project_model.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../../domain/entities/org_member.dart';

class TaskFlowMockDataSource {
  final LocalStorageService _localStorageService;
  final DebugOptionsManager _debugOptionsManager;

  List<OrganizationModel> _organizations = [];
  List<UserModel> _users = [];
  List<OrgMemberModel> _orgMembers = [];
  List<ProjectModel> _projects = [];
  List<TaskModel> _tasks = [];
  List<CommentModel> _comments = [];
  List<NotificationModel> _notifications = [];
  Map<String, dynamic> _authMockData = {};

  bool _isInitialized = false;

  TaskFlowMockDataSource(this._localStorageService, this._debugOptionsManager);

  Future<void> init() async {
    if (_isInitialized) return;

    final cachedJson = _localStorageService.getCachedData();
    String jsonString;
    if (cachedJson != null && cachedJson.isNotEmpty) {
      jsonString = cachedJson;
    } else {
      jsonString = await rootBundle.loadString('assets/mock_data/TaskFlow-MockData.json');
      await _localStorageService.saveCachedData(jsonString);
    }

    _parseAndSetData(jsonString);
    _isInitialized = true;
  }

  void _parseAndSetData(String jsonString) {
    final data = json.decode(jsonString) as Map<String, dynamic>;

    _organizations = (data['organizations'] as List<dynamic>?)
            ?.map((e) => OrganizationModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    _users = (data['users'] as List<dynamic>?)
            ?.map((e) => UserModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    _orgMembers = (data['org_members'] as List<dynamic>?)
            ?.map((e) => OrgMemberModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    _projects = (data['projects'] as List<dynamic>?)
            ?.map((e) => ProjectModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    _tasks = (data['tasks'] as List<dynamic>?)
            ?.map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    _comments = (data['comments'] as List<dynamic>?)
            ?.map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    _notifications = (data['notifications'] as List<dynamic>?)
            ?.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    _authMockData = data['auth_mock'] as Map<String, dynamic>? ?? {};
  }

  Future<void> _persistCurrentState() async {
    final map = {
      'organizations': _organizations.map((e) => e.toJson()).toList(),
      'users': _users.map((e) => e.toJson()).toList(),
      'org_members': _orgMembers.map((e) => e.toJson()).toList(),
      'projects': _projects.map((e) => e.toJson()).toList(),
      'tasks': _tasks.map((e) => e.toJson()).toList(),
      'comments': _comments.map((e) => e.toJson()).toList(),
      'notifications': _notifications.map((e) => e.toJson()).toList(),
      'auth_mock': _authMockData,
    };
    await _localStorageService.saveCachedData(json.encode(map));
  }

  // --- Auth Mock methods ---
  Future<Map<String, dynamic>> login(String email, String password) async {
    await _debugOptionsManager.simulateNetworkLatency();
    _debugOptionsManager.checkAndThrowSimulatedErrors();

    final usersList = (_authMockData['users'] as List<dynamic>?) ?? [];
    final match = usersList.firstWhere(
      (u) => u['email'] == email && u['password'] == password,
      orElse: () => null,
    );

    if (match == null) {
      throw const AuthException('Invalid email or password', code: 'INVALID_CREDENTIALS');
    }

    final expiresSeconds = _authMockData['access_token_expires_in_seconds'] as int? ?? 900;

    return {
      'user_id': match['user_id'],
      'org_id': match['org_id'],
      'role': match['role'],
      'access_token': match['access_token'],
      'refresh_token': match['refresh_token'],
      'expires_in_seconds': expiresSeconds,
    };
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String orgId,
  }) async {
    await _debugOptionsManager.simulateNetworkLatency();
    _debugOptionsManager.checkAndThrowSimulatedErrors();

    final newUserId = 'usr-${DateTime.now().millisecondsSinceEpoch}';
    final newUser = UserModel(
      id: newUserId,
      name: name,
      email: email,
      createdAt: DateTime.now(),
    );
    _users.add(newUser);

    final newMember = OrgMemberModel(
      id: 'mem-${DateTime.now().millisecondsSinceEpoch}',
      orgId: orgId,
      userId: newUserId,
      role: OrgRole.member,
      joinedAt: DateTime.now(),
    );
    _orgMembers.add(newMember);

    final mockToken = 'mock-jwt-token-$newUserId';
    final mockRefresh = 'mock-refresh-token-$newUserId';

    await _persistCurrentState();

    return {
      'user_id': newUserId,
      'org_id': orgId,
      'role': 'member',
      'access_token': mockToken,
      'refresh_token': mockRefresh,
      'expires_in_seconds': 900,
    };
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    await _debugOptionsManager.simulateNetworkLatency();
    _debugOptionsManager.checkAndThrowSimulatedErrors();

    if (!refreshToken.startsWith('mock-refresh-token-')) {
      throw const AuthException('Invalid or expired refresh token', code: 'INVALID_REFRESH_TOKEN');
    }

    final newAccessToken = 'mock-jwt-token-refreshed-${DateTime.now().millisecondsSinceEpoch}';
    final newRefreshToken = 'mock-refresh-token-refreshed-${DateTime.now().millisecondsSinceEpoch}';

    return {
      'access_token': newAccessToken,
      'refresh_token': newRefreshToken,
      'expires_in_seconds': 900,
    };
  }

  // --- Projects methods ---
  Future<List<ProjectModel>> getProjects(String orgId) async {
    await _debugOptionsManager.simulateNetworkLatency();
    _debugOptionsManager.checkAndThrowSimulatedErrors();
    return _projects.where((p) => p.orgId == orgId).toList();
  }

  Future<ProjectModel> getProjectById(String projectId) async {
    await _debugOptionsManager.simulateNetworkLatency();
    _debugOptionsManager.checkAndThrowSimulatedErrors();
    return _projects.firstWhere(
      (p) => p.id == projectId,
      orElse: () => throw const NotFoundException('Project not found', code: 'PROJECT_NOT_FOUND'),
    );
  }

  Future<ProjectModel> createProject(ProjectModel project) async {
    await _debugOptionsManager.simulateNetworkLatency();
    _debugOptionsManager.checkAndThrowSimulatedErrors();

    _projects.add(project);
    await _persistCurrentState();
    return project;
  }

  Future<ProjectModel> updateProject(ProjectModel project) async {
    await _debugOptionsManager.simulateNetworkLatency();
    _debugOptionsManager.checkAndThrowSimulatedErrors();

    final idx = _projects.indexWhere((p) => p.id == project.id);
    if (idx == -1) {
      throw const NotFoundException('Project not found', code: 'PROJECT_NOT_FOUND');
    }
    _projects[idx] = project;
    await _persistCurrentState();
    return project;
  }

  Future<void> deleteProject(String projectId) async {
    await _debugOptionsManager.simulateNetworkLatency();
    _debugOptionsManager.checkAndThrowSimulatedErrors();

    _projects.removeWhere((p) => p.id == projectId);
    _tasks.removeWhere((t) => t.projectId == projectId);
    await _persistCurrentState();
  }

  // --- Tasks methods ---
  Future<List<TaskModel>> getTasks(String orgId) async {
    await _debugOptionsManager.simulateNetworkLatency();
    _debugOptionsManager.checkAndThrowSimulatedErrors();
    return _tasks.where((t) => t.orgId == orgId).toList();
  }

  Future<TaskModel> getTaskById(String taskId) async {
    await _debugOptionsManager.simulateNetworkLatency();
    _debugOptionsManager.checkAndThrowSimulatedErrors();
    return _tasks.firstWhere(
      (t) => t.id == taskId,
      orElse: () => throw const NotFoundException('Task not found', code: 'TASK_NOT_FOUND'),
    );
  }

  Future<TaskModel> createTask(TaskModel task) async {
    await _debugOptionsManager.simulateNetworkLatency();
    _debugOptionsManager.checkAndThrowSimulatedErrors();

    _tasks.add(task);
    await _persistCurrentState();
    return task;
  }

  Future<TaskModel> updateTask(TaskModel task) async {
    await _debugOptionsManager.simulateNetworkLatency();
    _debugOptionsManager.checkAndThrowSimulatedErrors();

    final idx = _tasks.indexWhere((t) => t.id == task.id);
    if (idx == -1) {
      throw const NotFoundException('Task not found', code: 'TASK_NOT_FOUND');
    }
    _tasks[idx] = task;
    await _persistCurrentState();
    return task;
  }

  Future<void> deleteTask(String taskId) async {
    await _debugOptionsManager.simulateNetworkLatency();
    _debugOptionsManager.checkAndThrowSimulatedErrors();

    _tasks.removeWhere((t) => t.id == taskId);
    _comments.removeWhere((c) => c.taskId == taskId);
    await _persistCurrentState();
  }

  // --- Users & Org Members ---
  Future<List<UserModel>> getOrgUsers(String orgId) async {
    await _debugOptionsManager.simulateNetworkLatency();
    _debugOptionsManager.checkAndThrowSimulatedErrors();

    final memberUserIds = _orgMembers
        .where((m) => m.orgId == orgId)
        .map((m) => m.userId)
        .toSet();

    return _users.where((u) => memberUserIds.contains(u.id)).toList();
  }

  Future<OrgMemberModel?> getOrgMember(String orgId, String userId) async {
    final matches = _orgMembers.where((m) => m.orgId == orgId && m.userId == userId);
    return matches.isNotEmpty ? matches.first : null;
  }

  Future<UserModel?> getUserById(String userId) async {
    final matches = _users.where((u) => u.id == userId);
    return matches.isNotEmpty ? matches.first : null;
  }

  // --- Comments ---
  Future<List<CommentModel>> getComments(String taskId) async {
    await _debugOptionsManager.simulateNetworkLatency();
    _debugOptionsManager.checkAndThrowSimulatedErrors();
    return _comments.where((c) => c.taskId == taskId).toList();
  }

  Future<CommentModel> addComment(CommentModel comment) async {
    await _debugOptionsManager.simulateNetworkLatency();
    _debugOptionsManager.checkAndThrowSimulatedErrors();

    _comments.add(comment);
    await _persistCurrentState();
    return comment;
  }

  // --- Notifications ---
  Future<List<NotificationModel>> getNotifications(String userId) async {
    await _debugOptionsManager.simulateNetworkLatency();
    _debugOptionsManager.checkAndThrowSimulatedErrors();
    return _notifications.where((n) => n.userId == userId).toList();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      _notifications[idx] = NotificationModel(
        id: _notifications[idx].id,
        userId: _notifications[idx].userId,
        taskId: _notifications[idx].taskId,
        title: _notifications[idx].title,
        message: _notifications[idx].message,
        isRead: true,
        createdAt: _notifications[idx].createdAt,
      );
      await _persistCurrentState();
    }
  }

  void addNotification(NotificationModel notification) {
    _notifications.add(notification);
    _persistCurrentState();
  }
}
