import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../app/theme.dart';

class LoadingList extends StatelessWidget {
  const LoadingList({super.key, this.count = 4, this.shrinkWrap = false});

  final int count;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.surface,
      child: ListView.separated(
        shrinkWrap: shrinkWrap,
        physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
        padding: shrinkWrap ? EdgeInsets.zero : const EdgeInsets.all(16),
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => Container(
          height: 88,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
