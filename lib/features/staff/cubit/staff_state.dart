part of 'staff_cubit.dart';

enum StaffSort {
  newest('Newest first'),
  mostUpvoted('Most "me too"'),
  priority('Highest priority');

  const StaffSort(this.label);
  final String label;
}

class StaffState extends Equatable {
  const StaffState({
    this.status = LoadStatus.loading,
    this.all = const [],
    this.query = '',
    this.statusFilter,
    this.categoryFilter,
    this.sort = StaffSort.newest,
    this.errorMessage,
  });

  final LoadStatus status;
  final List<Incident> all;
  final String query;
  final IncidentStatus? statusFilter;
  final IncidentCategory? categoryFilter;
  final StaffSort sort;
  final String? errorMessage;

  int count(IncidentStatus status) =>
      all.where((i) => i.status == status).length;

  /// Counts for the status tabs; `null` is "All".
  Map<IncidentStatus?, int> get counts => {
    null: all.length,
    for (final s in IncidentStatus.values) s: count(s),
  };

  List<Incident> get filtered {
    final list = all
        .where(
          (i) => i.matches(
            query: query,
            status: statusFilter,
            category: categoryFilter,
          ),
        )
        .toList();
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

  StaffState copyWith({
    LoadStatus? status,
    List<Incident>? all,
    String? query,
    IncidentStatus? Function()? statusFilter,
    IncidentCategory? Function()? categoryFilter,
    StaffSort? sort,
    String? errorMessage,
  }) {
    return StaffState(
      status: status ?? this.status,
      all: all ?? this.all,
      query: query ?? this.query,
      statusFilter: statusFilter != null ? statusFilter() : this.statusFilter,
      categoryFilter: categoryFilter != null
          ? categoryFilter()
          : this.categoryFilter,
      sort: sort ?? this.sort,
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
    sort,
    errorMessage,
  ];
}
