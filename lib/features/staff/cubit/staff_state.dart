part of 'staff_cubit.dart';

enum StaffSort {
  newest('Newest first'),
  mostUpvoted('Most "me too"'),
  priority('Highest priority');

  const StaffSort(this.label);
  final String label;
}

class StaffState extends IncidentListState<StaffState> {
  const StaffState({
    super.status,
    super.all,
    super.query,
    super.statusFilter,
    super.categoryFilter,
    super.errorMessage,
    this.sort = StaffSort.newest,
  });

  final StaffSort sort;

  /// Counts for the status tabs; `null` is "All".
  Map<IncidentStatus?, int> get counts => {
    null: all.length,
    for (final s in IncidentStatus.values) s: count(s),
  };

  /// High-priority reports that are still open.
  int get urgentCount => all
      .where(
        (i) =>
            i.priority == IncidentPriority.high &&
            (i.status == IncidentStatus.submitted ||
                i.status == IncidentStatus.inProgress),
      )
      .length;

  /// How many of the extra filters (category, non-default sort) are on.
  int get activeFilterCount =>
      (categoryFilter == null ? 0 : 1) + (sort == StaffSort.newest ? 0 : 1);

  /// Reports submitted since [seenAt]; every submitted report counts when
  /// staff have never opened the alerts.
  int newReportCount(DateTime? seenAt) => all
      .where(
        (i) => seenAt == null
            ? i.status == IncidentStatus.submitted
            : i.createdAtOrNow.isAfter(seenAt),
      )
      .length;

  @override
  List<Incident> get filtered {
    final list = super.filtered;
    switch (sort) {
      case StaffSort.newest:
        break; // Already newest first from the repository.
      case StaffSort.mostUpvoted:
        list.sort((a, b) => b.upvoteCount.compareTo(a.upvoteCount));
      case StaffSort.priority:
        list.sort((a, b) => b.priority.index.compareTo(a.priority.index));
    }
    return list;
  }

  @override
  StaffState copyWith({
    LoadStatus? status,
    List<Incident>? all,
    String? query,
    IncidentStatus? Function()? statusFilter,
    IncidentCategory? Function()? categoryFilter,
    String? errorMessage,
    StaffSort? sort,
  }) {
    return StaffState(
      status: status ?? this.status,
      all: all ?? this.all,
      query: query ?? this.query,
      statusFilter: statusFilter != null ? statusFilter() : this.statusFilter,
      categoryFilter: categoryFilter != null
          ? categoryFilter()
          : this.categoryFilter,
      errorMessage: errorMessage ?? this.errorMessage,
      sort: sort ?? this.sort,
    );
  }

  @override
  List<Object?> get props => [...super.props, sort];
}
