import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/models/app_user.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar(this.user, {super.key, this.radius = 22, this.ring = false});

  final AppUser user;
  final double radius;

  /// Draws an orange ring around the avatar (used on dark headers).
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final url = user.photoUrl;
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.accentTint,
      foregroundImage: url == null || url.isEmpty ? null : NetworkImage(url),
      child: Text(
        user.initials,
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.7,
        ),
      ),
    );
    if (!ring) return avatar;
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: const BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
      ),
      child: avatar,
    );
  }
}
