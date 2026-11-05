import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme.dart';
import '../../../core/extensions.dart';
import '../../../data/models/incident.dart';
import '../cubit/staff_cubit.dart';

/// Sort order and category filter for the staff queue. Changes apply as
/// they are tapped.
Future<void> showStaffFilterSheet(BuildContext context) {
  final cubit = context.read<StaffCubit>();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (_) => BlocProvider.value(value: cubit, child: const _Sheet()),
  );
}

class _Sheet extends StatelessWidget {
  const _Sheet();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<StaffCubit>();
    return BlocBuilder<StaffCubit, StaffState>(
      builder: (context, state) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filters',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (state.activeFilterCount > 0)
                    TextButton(
                      onPressed: () => cubit
                        ..setSort(StaffSort.newest)
                        ..setCategoryFilter(null),
                      child: const Text('Reset'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const _Heading('Sort by'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in StaffSort.values)
                    _Option(
                      label: s.label,
                      selected: state.sort == s,
                      onTap: () => cubit.setSort(s),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const _Heading('Category'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Option(
                    label: 'All',
                    selected: state.categoryFilter == null,
                    onTap: () => cubit.setCategoryFilter(null),
                  ),
                  for (final c in IncidentCategory.values)
                    _Option(
                      label: c.label,
                      icon: c.icon,
                      selected: state.categoryFilter == c,
                      onTap: () => cubit.setCategoryFilter(c),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Show ${state.filtered.length} reports'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : AppColors.textPrimary;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: AppColors.background,
      avatar: icon == null ? null : Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color)),
    );
  }
}
