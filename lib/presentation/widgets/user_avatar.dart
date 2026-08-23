import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double radius;

  const UserAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.radius = 16,
  });

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Color _getBackgroundColor() {
    final hash = name.codeUnits.fold(0, (prev, elem) => prev + elem);
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      AppColors.statusInProgress,
      AppColors.statusReview,
    ];
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(avatarUrl!),
        backgroundColor: _getBackgroundColor(),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: _getBackgroundColor(),
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.85,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
