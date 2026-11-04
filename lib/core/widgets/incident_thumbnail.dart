import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/models/incident.dart';
import '../extensions.dart';

/// First photo of an incident, or its category icon when there is none.
class IncidentThumbnail extends StatelessWidget {
  const IncidentThumbnail(this.incident, {super.key, this.size = 64});

  final Incident incident;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: AppColors.primaryTint,
      alignment: Alignment.center,
      child: Icon(
        incident.category.icon,
        color: AppColors.primary,
        size: size * 0.42,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox.square(
        dimension: size,
        child: incident.thumbnail == null
            ? placeholder
            : Image.memory(
                incident.thumbnail!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}
