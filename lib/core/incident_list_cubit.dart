import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/incident.dart';
import 'load_status.dart';

/// State shared by the student's and the staff's report lists: the live list
/// plus the search text and filters applied to it on the client.
abstract class IncidentListState<S extends IncidentListState<S>>
    extends Equatable {
  const IncidentListState({
    this.status = LoadStatus.loading,
    this.all = const [],
    this.query = '',
    this.statusFilter,
    this.categoryFilter,
    this.errorMessage,
  });

  final LoadStatus status;
  final List<Incident> all;
  final String query;
  final IncidentStatus? statusFilter;
  final IncidentCategory? categoryFilter;
  final String? errorMessage;

  List<Incident> get filtered => all
      .where(
        (i) => i.matches(
          query: query,
          status: statusFilter,
          category: categoryFilter,
        ),
      )
      .toList();

  int count(IncidentStatus status) =>
      all.where((i) => i.status == status).length;

  S copyWith({
    LoadStatus? status,
    List<Incident>? all,
    String? query,
    IncidentStatus? Function()? statusFilter,
    IncidentCategory? Function()? categoryFilter,
    String? errorMessage,
  });

  @override
  List<Object?> get props => [
    status,
    all,
    query,
    statusFilter,
    categoryFilter,
    errorMessage,
  ];
}

/// Subscribes to a list of incidents and keeps search and filters in state.
abstract class IncidentListCubit<S extends IncidentListState<S>>
    extends Cubit<S> {
  IncidentListCubit(super.initialState);

  StreamSubscription<List<Incident>>? _sub;

  Stream<List<Incident>> get incidents;

  String get loadErrorMessage;

  void watch() {
    _sub?.cancel();
    _sub = incidents.listen(
      (incidents) =>
          emit(state.copyWith(status: LoadStatus.loaded, all: incidents)),
      onError: (Object _) => emit(
        state.copyWith(
          status: LoadStatus.failure,
          errorMessage: loadErrorMessage,
        ),
      ),
    );
  }

  /// Pull-to-refresh. The list is live already; re-subscribing recovers from
  /// an earlier error.
  Future<void> refresh() async {
    watch();
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  void search(String query) => emit(state.copyWith(query: query));

  void setStatusFilter(IncidentStatus? status) =>
      emit(state.copyWith(statusFilter: () => status));

  void setCategoryFilter(IncidentCategory? category) =>
      emit(state.copyWith(categoryFilter: () => category));

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
