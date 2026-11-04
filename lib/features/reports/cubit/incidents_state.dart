part of 'incidents_cubit.dart';

class IncidentsState extends Equatable {
  const IncidentsState({
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

  List<Incident> get notifications =>
      all.where((i) => i.hasStaffUpdate).toList()
        ..sort((a, b) => b.updatedAt!.compareTo(a.updatedAt!));

  /// Updates newer than [seenAt]; everything counts when it's null.
  int unreadCount(DateTime? seenAt) => notifications
      .where((i) => seenAt == null || i.updatedAt!.isAfter(seenAt))
      .length;

  IncidentsState copyWith({
    LoadStatus? status,
    List<Incident>? all,
    String? query,
    IncidentStatus? Function()? statusFilter,
    IncidentCategory? Function()? categoryFilter,
    String? errorMessage,
  }) {
    return IncidentsState(
      status: status ?? this.status,
      all: all ?? this.all,
      query: query ?? this.query,
      statusFilter: statusFilter != null ? statusFilter() : this.statusFilter,
      categoryFilter: categoryFilter != null
          ? categoryFilter()
          : this.categoryFilter,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

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
