import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user.dart';
import 'auth_provider.dart';
import 'core_providers.dart';

final orgMembersProvider = FutureProvider<List<User>>((ref) async {
  final authState = ref.watch(authProvider);
  final userRepo = ref.watch(userRepositoryProvider);

  if (authState.orgId == null || authState.orgId!.isEmpty) {
    return [];
  }

  return await userRepo.getOrgMembers(authState.orgId!);
});

final userDetailProvider = FutureProvider.family<User?, String>((ref, userId) async {
  final userRepo = ref.watch(userRepositoryProvider);
  return await userRepo.getUserById(userId);
});
