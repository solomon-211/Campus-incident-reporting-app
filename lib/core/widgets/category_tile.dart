import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/models/incident.dart';
import '../extensions.dart';

class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final IncidentCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: selected ? AppColors.accent : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: selected ? null : AppShadows.soft,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(category.icon, color: fg, size: 24),
                const SizedBox(height: 6),
                Text(
                  category.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
