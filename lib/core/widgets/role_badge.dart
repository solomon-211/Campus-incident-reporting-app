import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/models/app_user.dart';

/// Orange "Student" / "Staff" tag.
class RoleBadge extends StatelessWidget {
  const RoleBadge(this.role, {super.key, this.large = false});

  final UserRole role;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 8,
        vertical: large ? 4 : 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role == UserRole.staff ? 'Staff' : 'Student',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: large ? 14 : 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
