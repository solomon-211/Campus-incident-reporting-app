import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../extensions.dart';
import '../../data/models/incident.dart';

class StatusTabs extends StatelessWidget {
  const StatusTabs({
    super.key,
    required this.selected,
    required this.onSelected,
    this.counts,
  });

  final IncidentStatus? selected;
  final ValueChanged<IncidentStatus?> onSelected;

  final Map<IncidentStatus?, int>? counts;

  @override
  Widget build(BuildContext context) {
    final options = <IncidentStatus?>[null, ...IncidentStatus.values];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final status = options[i];
          final isSelected = status == selected;
          final count = counts?[status];
          return ChoiceChip(
            selected: isSelected,
            onSelected: (_) => onSelected(status),
            label: Text(
              '${status?.label ?? 'All'}${count == null ? '' : ' ($count)'}',
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          );
        },
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
    this.hint = 'Search by title, location or description',
  });

  final ValueChanged<String> onChanged;
  final String initialValue;
  final String hint;

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
        hintText: widget.hint,
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
