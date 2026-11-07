import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../extensions.dart';
import '../../data/models/incident.dart';

class StatusTabs extends StatelessWidget {
  const StatusTabs({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final IncidentStatus? selected;
  final ValueChanged<IncidentStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    final options = <IncidentStatus?>[null, ...IncidentStatus.values];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final status in options)
            Expanded(
              child: _StatusSegment(
                label: status?.label ?? 'All',
                selected: status == selected,
                onTap: () => onSelected(status),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusSegment extends StatelessWidget {
  const _StatusSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Search box that keeps its own controller so typing isn't interrupted by
/// rebuilds.
class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    required this.onChanged,
    this.initialValue = '',
  });

  final ValueChanged<String> onChanged;
  final String initialValue;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void didUpdateWidget(SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Follow external resets (e.g. Home clearing the search).
    if (widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: (v) {
        widget.onChanged(v);
        setState(() {});
      },
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search by title, location or description',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                  setState(() {});
                },
              ),
      ),
    );
  }
}

class CategoryFilterButton extends StatelessWidget {
  const CategoryFilterButton({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final IncidentCategory? selected;
  final ValueChanged<IncidentCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<IncidentCategory?>(
      tooltip: 'Filter by category',
      icon: Badge(
        isLabelVisible: selected != null,
        smallSize: 8,
        child: const Icon(Icons.tune_rounded),
      ),
      onSelected: onSelected,
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: null,
          checked: selected == null,
          child: const Text('All categories'),
        ),
        for (final c in IncidentCategory.values)
          CheckedPopupMenuItem(
            value: c,
            checked: selected == c,
            child: Row(
              children: [
                Icon(c.icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(c.label),
              ],
            ),
          ),
      ],
    );
  }
}
