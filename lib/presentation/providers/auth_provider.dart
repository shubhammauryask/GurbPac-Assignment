import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/auth_token.dart';
import '../../domain/entities/org_member.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'core_providers.dart';

enum AuthStatus {
  uninitialized,
  unauthenticated,
  authenticating,
  authenticated,
  tokenExpired,
  error,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  final String? orgId;
  final OrgRole? role;
  final AuthToken? token;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.orgId,
    this.role,
    this.token,
    this.errorMessage,
  });

  factory AuthState.uninitialized() => const AuthState(status: AuthStatus.uninitialized);
  factory AuthState.unauthenticated() => const AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.authenticating() => const AuthState(status: AuthStatus.authenticating);
  factory AuthState.authenticated({
    required User user,
    required String orgId,
    required OrgRole role,
    required AuthToken token,
  }) =>
      AuthState(
        status: AuthStatus.authenticated,
        user: user,
        orgId: orgId,
        role: role,
        token: token,
      );
  factory AuthState.error(String message) =>
      AuthState(status: AuthStatus.error, errorMessage: message);

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isAdmin => role == OrgRole.orgAdmin;

  @override
  List<Object?> get props => [status, user, orgId, role, token, errorMessage];
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  Timer? _refreshTimer;

  AuthNotifier(this._repository) : super(AuthState.uninitialized());

  Future<void> checkSession() async {
    state = AuthState.authenticating();
    try {
      final res = await _repository.checkSavedSession();
      if (res != null) {
        state = AuthState.authenticated(
          user: res.user,
          orgId: res.orgId,
          role: res.role,
          token: res.token,
        );
        _scheduleTokenRefresh(res.token);
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.unauthenticated();
    }
  }

  Future<bool> login(String email, String password) async {
    state = AuthState.authenticating();
    try {
      final res = await _repository.login(email: email, password: password);
      state = AuthState.authenticated(
        user: res.user,
        orgId: res.orgId,
        role: res.role,
        token: res.token,
      );
      _scheduleTokenRefresh(res.token);
      return true;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String orgId,
  }) async {
    state = AuthState.authenticating();
    try {
      final res = await _repository.register(
        name: name,
        email: email,
        password: password,
        orgId: orgId,
      );
      state = AuthState.authenticated(
        user: res.user,
        orgId: res.orgId,
        role: res.role,
        token: res.token,
      );
      _scheduleTokenRefresh(res.token);
      return true;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    _refreshTimer?.cancel();
    await _repository.logout();
    state = AuthState.unauthenticated();
  }

  Future<void> refreshCurrentToken() async {
    if (state.token == null) return;
    try {
      final newToken = await _repository.refreshToken(state.token!.refreshToken);
      state = AuthState.authenticated(
        user: state.user!,
        orgId: state.orgId!,
        role: state.role!,
        token: newToken,
      );
      _scheduleTokenRefresh(newToken);
    } catch (e) {
      logout();
    }
  }

  void _scheduleTokenRefresh(AuthToken token) {
    _refreshTimer?.cancel();
    final timeUntilExpiry = token.expiresAt.difference(DateTime.now());
    // Refresh 1 minute before expiry or immediately if short
    final refreshDuration = timeUntilExpiry.inSeconds > 60
        ? timeUntilExpiry - const Duration(minutes: 1)
        : const Duration(seconds: 10);

    _refreshTimer = Timer(refreshDuration, () {
      refreshCurrentToken();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});
