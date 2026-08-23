import '../../domain/entities/org_member.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/taskflow_mock_datasource.dart';

class UserRepositoryImpl implements UserRepository {
  final TaskFlowMockDataSource _dataSource;

  UserRepositoryImpl(this._dataSource);

  @override
  Future<List<User>> getOrgMembers(String orgId) async {
    await _dataSource.init();
    return await _dataSource.getOrgUsers(orgId);
  }

  @override
  Future<OrgMember?> getOrgMember(String orgId, String userId) async {
    await _dataSource.init();
    return await _dataSource.getOrgMember(orgId, userId);
  }

  @override
  Future<User?> getUserById(String userId) async {
    await _dataSource.init();
    return await _dataSource.getUserById(userId);
  }
}
