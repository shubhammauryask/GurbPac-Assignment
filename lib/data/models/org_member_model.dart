import '../../domain/entities/org_member.dart';

class OrgMemberModel extends OrgMember {
  const OrgMemberModel({
    required super.id,
    required super.orgId,
    required super.userId,
    required super.role,
    required super.joinedAt,
  });

  factory OrgMemberModel.fromJson(Map<String, dynamic> json) {
    return OrgMemberModel(
      id: json['id'] as String,
      orgId: json['org_id'] as String,
      userId: json['user_id'] as String,
      role: (json['role'] as String) == 'org_admin'
          ? OrgRole.orgAdmin
          : OrgRole.member,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'org_id': orgId,
      'user_id': userId,
      'role': role == OrgRole.orgAdmin ? 'org_admin' : 'member',
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}
