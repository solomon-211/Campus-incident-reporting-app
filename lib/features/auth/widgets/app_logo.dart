import 'package:flutter/material.dart';

import '../../../app/theme.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        Icons.campaign_rounded,
        size: size * 0.56,
        color: AppColors.primary,
      ),
    );
  }
}
