part of 'incident_detail_cubit.dart';

enum DetailStatus { loading, loaded, notFound, failure }

class IncidentDetailState extends Equatable {
  const IncidentDetailState({
    this.status = DetailStatus.loading,
    this.incident,
    this.timeline = const [],
    this.photos = const [],
    this.photosLoading = false,
    this.errorMessage,
  });

  final DetailStatus status;
  final Incident? incident;

  /// Oldest first.
  final List<StatusUpdate> timeline;

  final List<Uint8List> photos;
  final bool photosLoading;
  final String? errorMessage;

  /// Most recent time the incident entered [status], if it ever did.
  DateTime? reachedAt(IncidentStatus status) {
    final matches = timeline.where((u) => u.status == status);
    return matches.isEmpty ? null : matches.last.timestamp;
  }

  IncidentDetailState copyWith({
    DetailStatus? status,
    Incident? incident,
    List<StatusUpdate>? timeline,
    List<Uint8List>? photos,
    bool? photosLoading,
    String? errorMessage,
  }) {
    return IncidentDetailState(
      status: status ?? this.status,
      incident: incident ?? this.incident,
      timeline: timeline ?? this.timeline,
      photos: photos ?? this.photos,
      photosLoading: photosLoading ?? this.photosLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    incident,
    timeline,
    photos,
    photosLoading,
    errorMessage,
  ];
}
