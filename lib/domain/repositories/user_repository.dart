import '../entities/org_member.dart';
import '../entities/user.dart';

abstract class UserRepository {
  Future<List<User>> getOrgMembers(String orgId);

  Future<OrgMember?> getOrgMember(String orgId, String userId);

  Future<User?> getUserById(String userId);
}
