part of 'my_reports_cubit.dart';

class MyReportsState extends IncidentListState<MyReportsState> {
  const MyReportsState({
    super.status,
    super.all,
    super.query,
    super.statusFilter,
    super.categoryFilter,
    super.errorMessage,
  });

  /// Reports staff have updated, most recent first.
  List<Incident> get notifications =>
      all.where((i) => i.hasStaffUpdate).toList()
        ..sort((a, b) => b.updatedAt!.compareTo(a.updatedAt!));

  /// Updates newer than [seenAt]; everything counts when it's null.
  int unreadCount(DateTime? seenAt) => notifications
      .where((i) => seenAt == null || i.updatedAt!.isAfter(seenAt))
      .length;

  @override
  MyReportsState copyWith({
    LoadStatus? status,
    List<Incident>? all,
    String? query,
    IncidentStatus? Function()? statusFilter,
    IncidentCategory? Function()? categoryFilter,
    String? errorMessage,
  }) {
    return MyReportsState(
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
}
