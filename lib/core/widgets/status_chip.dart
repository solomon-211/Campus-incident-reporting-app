import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/models/incident.dart';
import '../extensions.dart';

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key, this.dense = false});

  final IncidentStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final dot = dense ? 6.0 : 7.0;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: dot,
            height: dot,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: dense ? 5 : 6),
          Text(
            status.label,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: dense ? 11 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
