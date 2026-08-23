import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_flow/core/errors/failures.dart';
import 'package:task_flow/core/network/debug_options_manager.dart';
import 'package:task_flow/core/storage/local_storage_service.dart';
import 'package:task_flow/core/storage/secure_storage_service.dart';
import 'package:task_flow/data/datasources/taskflow_mock_datasource.dart';
import 'package:task_flow/data/repositories/auth_repository_impl.dart';
import 'package:task_flow/domain/entities/org_member.dart';

class FakeFlutterSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _map = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _map[key] = value;
    } else {
      _map.remove(key);
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _map[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _map.remove(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TaskFlowMockDataSource dataSource;
  late AuthRepositoryImpl authRepository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final localStorage = LocalStorageService(prefs);
    final debugOpts = DebugOptionsManager(simulatedDelayMs: 0);
    dataSource = TaskFlowMockDataSource(localStorage, debugOpts);
    final fakeStorage = SecureStorageService(storage: FakeFlutterSecureStorage());
    authRepository = AuthRepositoryImpl(dataSource, fakeStorage);
  });

  group('Authentication Unit Tests', () {
    test('Login with valid Org A Admin credentials returns AuthResult', () async {
      final res = await authRepository.login(
        email: 'alex@acme.com',
        password: 'password123',
      );

      expect(res.user.email, equals('alex@acme.com'));
      expect(res.orgId, equals('org-1'));
      expect(res.role, equals(OrgRole.orgAdmin));
      expect(res.token.accessToken, isNotEmpty);
      expect(res.token.isExpired, isFalse);
    });

    test('Login with invalid credentials throws AuthException', () async {
      expect(
        () async => await authRepository.login(
          email: 'alex@acme.com',
          password: 'wrongpassword',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('RefreshToken exchanges mock refresh token for new access token', () async {
      final newTokens = await authRepository.refreshToken(
        'mock-refresh-token-alex-acme-admin',
      );

      expect(newTokens.accessToken, startsWith('mock-jwt-token-refreshed-'));
      expect(newTokens.refreshToken, startsWith('mock-refresh-token-refreshed-'));
      expect(newTokens.isExpired, isFalse);
    });
  });
}
