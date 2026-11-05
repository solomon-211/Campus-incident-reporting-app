import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/incident.dart';
import '../extensions.dart';
import 'incident_list_cubit.dart';
import '../load_status.dart';

/// Reports in [current] that weren't in [previous].
List<Incident> newIncidents(List<Incident> previous, List<Incident> current) {
  final known = {for (final i in previous) i.id};
  return current.where((i) => !known.contains(i.id)).toList();
}

/// Reports whose status differs between [previous] and [current].
List<Incident> statusChanges(List<Incident> previous, List<Incident> current) {
  final before = {for (final i in previous) i.id: i.status};
  return current
      .where((i) => before.containsKey(i.id) && before[i.id] != i.status)
      .toList();
}

/// Shows a banner whenever [alertsFor] finds something worth telling the
/// user about in a list update. The first load never alerts.
class IncidentAlertListener<
  C extends IncidentListCubit<S>,
  S extends IncidentListState<S>
>
    extends StatefulWidget {
  const IncidentAlertListener({
    super.key,
    required this.alertsFor,
    required this.child,
  });

  final List<String> Function(List<Incident> previous, List<Incident> current)
  alertsFor;
  final Widget child;

  @override
  State<IncidentAlertListener<C, S>> createState() =>
      _IncidentAlertListenerState<C, S>();
}

class _IncidentAlertListenerState<
  C extends IncidentListCubit<S>,
  S extends IncidentListState<S>
>
    extends State<IncidentAlertListener<C, S>> {
  List<Incident>? _previous;

  @override
  Widget build(BuildContext context) {
    return BlocListener<C, S>(
      listener: (context, state) {
        if (state.status != LoadStatus.loaded) return;
        final previous = _previous;
        _previous = state.all;
        if (previous == null) return;
        final alerts = widget.alertsFor(previous, state.all);
        if (alerts.isEmpty) return;
        context.showSnack(
          alerts.length == 1 ? alerts.single : '${alerts.length} new updates',
          info: true,
        );
      },
      child: widget.child,
    );
  }
}
