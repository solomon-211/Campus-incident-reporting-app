import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme.dart';
import '../../../core/extensions.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/incident.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../cubit/staff_cubit.dart';

class UpdateStatusSheet extends StatefulWidget {
  const UpdateStatusSheet({super.key, required this.incident});

  final Incident incident;

  static Future<void> show(BuildContext context, Incident incident) {
    final staffCubit = context.read<StaffCubit>();
    final authCubit = context.read<AuthCubit>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: staffCubit),
          BlocProvider.value(value: authCubit),
        ],
        child: UpdateStatusSheet(incident: incident),
      ),
    );
  }

  @override
  State<UpdateStatusSheet> createState() => _UpdateStatusSheetState();
}

class _UpdateStatusSheetState extends State<UpdateStatusSheet> {
  final _note = TextEditingController();
  late IncidentStatus _status = _suggestedNext(widget.incident.status);
  late IncidentPriority _priority = widget.incident.priority;
  bool _saving = false;
  String? _noteError;

  static IncidentStatus _suggestedNext(IncidentStatus current) =>
      switch (current) {
        IncidentStatus.submitted => IncidentStatus.inProgress,
        IncidentStatus.inProgress => IncidentStatus.resolved,
        _ => current,
      };

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_note.text.trim().isEmpty) {
      setState(() => _noteError = 'A note is required');
      return;
    }
    final user = context.read<AuthCubit>().currentUser;
    if (user == null) return;

    setState(() {
      _saving = true;
      _noteError = null;
    });
    final error = await context.read<StaffCubit>().updateStatus(
      incidentId: widget.incident.id,
      status: _status,
      priority: _priority,
      note: _note.text,
      by: user,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      context.showSnack(error, error: true);
      return;
    }
    Navigator.pop(context);
    context.showSnack('Status updated to ${_status.label}');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Update status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              widget.incident.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            const Text(
              'New status',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in IncidentStatus.values)
                  ChoiceChip(
                    selected: _status == s,
                    onSelected: _saving
                        ? null
                        : (_) => setState(() => _status = s),
                    selectedColor: s.color,
                    avatar: Icon(
                      s.icon,
                      size: 16,
                      color: _status == s ? Colors.white : s.color,
                    ),
                    label: Text(
                      s.label,
                      style: TextStyle(
                        color: _status == s
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Priority',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SegmentedButton<IncidentPriority>(
              segments: [
                for (final p in IncidentPriority.values)
                  ButtonSegment(value: p, label: Text(p.label)),
              ],
              selected: {_priority},
              showSelectedIcon: false,
              onSelectionChanged: _saving
                  ? null
                  : (s) => setState(() => _priority = s.first),
            ),
            const SizedBox(height: 20),
            const Text(
              'Note to the reporter',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              enabled: !_saving,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) {
                if (_noteError != null) setState(() => _noteError = null);
              },
              decoration: InputDecoration(
                hintText: 'e.g. Plumber assigned, expected fix by tomorrow.',
                errorText: _noteError,
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Save update',
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class UpdateStatusButton extends StatelessWidget {
  const UpdateStatusButton({super.key, required this.incident});

  final Incident? incident;

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: 'Update status',
      icon: Icons.edit_note_rounded,
      onPressed: incident == null
          ? null
          : () => UpdateStatusSheet.show(context, incident!),
    );
  }
}
