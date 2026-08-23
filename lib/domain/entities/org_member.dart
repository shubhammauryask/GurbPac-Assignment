import 'package:equatable/equatable.dart';

enum OrgRole { orgAdmin, member }

class OrgMember extends Equatable {
  final String id;
  final String orgId;
  final String userId;
  final OrgRole role;
  final DateTime joinedAt;

  const OrgMember({
    required this.id,
    required this.orgId,
    required this.userId,
    required this.role,
    required this.joinedAt,
  });

  bool get isAdmin => role == OrgRole.orgAdmin;

  @override
  List<Object?> get props => [id, orgId, userId, role, joinedAt];
}
