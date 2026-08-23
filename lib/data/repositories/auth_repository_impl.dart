import 'dart:convert';
import '../../core/errors/failures.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../domain/entities/auth_token.dart';
import '../../domain/entities/org_member.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/taskflow_mock_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final TaskFlowMockDataSource _dataSource;
  final SecureStorageService _secureStorage;

  AuthRepositoryImpl(this._dataSource, this._secureStorage);

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    await _dataSource.init();
    final res = await _dataSource.login(email, password);

    final userId = res['user_id'] as String;
    final orgId = res['org_id'] as String;
    final roleStr = res['role'] as String;
    final accessToken = res['access_token'] as String;
    final refreshToken = res['refresh_token'] as String;
    final expiresSeconds = res['expires_in_seconds'] as int;

    final expiresAt = DateTime.now().add(Duration(seconds: expiresSeconds));
    final token = AuthToken(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );

    final user = await _dataSource.getUserById(userId);
    if (user == null) {
      throw const AuthException('User profile missing');
    }

    final role = roleStr == 'org_admin' ? OrgRole.orgAdmin : OrgRole.member;

    await _secureStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );

    final sessionMap = {
      'user': {
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'avatar_url': user.avatarUrl,
        'created_at': user.createdAt.toIso8601String(),
      },
      'org_id': orgId,
      'role': roleStr,
    };
    await _secureStorage.saveUserSession(json.encode(sessionMap));

    return AuthResult(
      user: user,
      orgId: orgId,
      role: role,
      token: token,
    );
  }

  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String orgId,
  }) async {
    await _dataSource.init();
    final res = await _dataSource.register(
      name: name,
      email: email,
      password: password,
      orgId: orgId,
    );

    final userId = res['user_id'] as String;
    final roleStr = res['role'] as String;
    final accessToken = res['access_token'] as String;
    final refreshToken = res['refresh_token'] as String;
    final expiresSeconds = res['expires_in_seconds'] as int;

    final expiresAt = DateTime.now().add(Duration(seconds: expiresSeconds));
    final token = AuthToken(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );

    final user = await _dataSource.getUserById(userId);
    if (user == null) {
      throw const AuthException('User profile missing after registration');
    }

    final role = roleStr == 'org_admin' ? OrgRole.orgAdmin : OrgRole.member;

    await _secureStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );

    final sessionMap = {
      'user': {
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'avatar_url': user.avatarUrl,
        'created_at': user.createdAt.toIso8601String(),
      },
      'org_id': orgId,
      'role': roleStr,
    };
    await _secureStorage.saveUserSession(json.encode(sessionMap));

    return AuthResult(
      user: user,
      orgId: orgId,
      role: role,
      token: token,
    );
  }

  @override
  Future<AuthToken> refreshToken(String refreshTokenStr) async {
    await _dataSource.init();
    final res = await _dataSource.refreshToken(refreshTokenStr);

    final accessToken = res['access_token'] as String;
    final newRefreshToken = res['refresh_token'] as String;
    final expiresSeconds = res['expires_in_seconds'] as int;

    final expiresAt = DateTime.now().add(Duration(seconds: expiresSeconds));

    await _secureStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: newRefreshToken,
      expiresAt: expiresAt,
    );

    return AuthToken(
      accessToken: accessToken,
      refreshToken: newRefreshToken,
      expiresAt: expiresAt,
    );
  }

  @override
  Future<void> logout() async {
    await _secureStorage.clearSession();
  }

  @override
  Future<AuthResult?> checkSavedSession() async {
    await _dataSource.init();

    final sessionJson = await _secureStorage.getUserSession();
    final accessToken = await _secureStorage.getAccessToken();
    final refreshTokenStr = await _secureStorage.getRefreshToken();
    final expiresAt = await _secureStorage.getTokenExpiry();

    if (sessionJson == null ||
        accessToken == null ||
        refreshTokenStr == null ||
        expiresAt == null) {
      return null;
    }

    final sessionMap = json.decode(sessionJson) as Map<String, dynamic>;
    final userMap = sessionMap['user'] as Map<String, dynamic>;
    final orgId = sessionMap['org_id'] as String;
    final roleStr = sessionMap['role'] as String;

    final user = User(
      id: userMap['id'] as String,
      name: userMap['name'] as String,
      email: userMap['email'] as String,
      avatarUrl: userMap['avatar_url'] as String?,
      createdAt: DateTime.parse(userMap['created_at'] as String),
    );

    final role = roleStr == 'org_admin' ? OrgRole.orgAdmin : OrgRole.member;

    var token = AuthToken(
      accessToken: accessToken,
      refreshToken: refreshTokenStr,
      expiresAt: expiresAt,
    );

    // If expired, attempt automatic token refresh
    if (token.isExpired) {
      try {
        token = await refreshToken(refreshTokenStr);
      } catch (_) {
        await logout();
        return null;
      }
    }

    return AuthResult(
      user: user,
      orgId: orgId,
      role: role,
      token: token,
    );
  }
}
