part of 'report_form_cubit.dart';

enum ReportFormStatus { editing, submitting, success, failure }

class ReportFormState extends Equatable {
  const ReportFormState({
    this.category,
    this.title = '',
    this.description = '',
    this.location,
    this.isAnonymous = false,
    this.images = const [],
    this.status = ReportFormStatus.editing,
    this.errorMessage,
    this.showErrors = false,
    this.createdIncidentId,
  });

  final IncidentCategory? category;
  final String title;
  final String description;
  final String? location;
  final bool isAnonymous;

  /// Raw bytes rather than files so this also works on web.
  final List<Uint8List> images;
  final ReportFormStatus status;

  final String? errorMessage;

  /// Errors are only shown after the first submit attempt.
  final bool showErrors;
  final String? createdIncidentId;

  bool get isSubmitting => status == ReportFormStatus.submitting;
  bool get canAddPhotos => images.length < AppConstants.maxPhotos;

  String? get categoryError =>
      category == null ? 'Please select a category' : null;
  String? get titleError => Validators.title(title);
  String? get descriptionError => Validators.description(description);
  String? get locationError => Validators.required(location, 'Location');
  String? get photosError => Validators.photoCount(images.length);

  bool get isValid =>
      categoryError == null &&
      titleError == null &&
      descriptionError == null &&
      locationError == null &&
      photosError == null;

  ReportFormState copyWith({
    IncidentCategory? category,
    String? title,
    String? description,
    String? location,
    bool? isAnonymous,
    List<Uint8List>? images,
    ReportFormStatus? status,
    String? errorMessage,
    bool clearError = false,
    bool? showErrors,
    String? createdIncidentId,
  }) {
    return ReportFormState(
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      images: images ?? this.images,
      status: status ?? this.status,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      showErrors: showErrors ?? this.showErrors,
      createdIncidentId: createdIncidentId ?? this.createdIncidentId,
    );
  }

  @override
  List<Object?> get props => [
    category,
    title,
    description,
    location,
    isAnonymous,
    images,
    status,
    errorMessage,
    showErrors,
    createdIncidentId,
  ];
}
