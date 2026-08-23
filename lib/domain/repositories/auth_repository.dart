import '../entities/auth_token.dart';
import '../entities/org_member.dart';
import '../entities/user.dart';

class AuthResult {
  final User user;
  final String orgId;
  final OrgRole role;
  final AuthToken token;

  const AuthResult({
    required this.user,
    required this.orgId,
    required this.role,
    required this.token,
  });
}

abstract class AuthRepository {
  Future<AuthResult> login({
    required String email,
    required String password,
  });

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String orgId,
  });

  Future<AuthToken> refreshToken(String refreshToken);

  Future<void> logout();

  Future<AuthResult?> checkSavedSession();
}
