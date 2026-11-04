import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants.dart';
import '../../../core/validators.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/incident.dart';
import '../../../data/repositories/incident_repository.dart';
import '../../../data/repositories/photo_repository.dart';

part 'report_form_state.dart';

class ReportFormCubit extends Cubit<ReportFormState> {
  ReportFormCubit(
    this._incidents,
    this._photos, {
    IncidentCategory? initialCategory,
  }) : super(ReportFormState(category: initialCategory));

  final IncidentRepository _incidents;
  final PhotoRepository _photos;

  void setCategory(IncidentCategory category) =>
      emit(state.copyWith(category: category));

  void setTitle(String title) => emit(state.copyWith(title: title));

  void setDescription(String description) =>
      emit(state.copyWith(description: description));

  void setLocation(String location) => emit(state.copyWith(location: location));

  void setAnonymous(bool value) => emit(state.copyWith(isAnonymous: value));

  /// Adds photos up to the limit. Returns how many were left out.
  int addImages(List<Uint8List> picked) {
    final room = AppConstants.maxPhotos - state.images.length;
    final accepted = picked.take(room).toList();
    emit(state.copyWith(images: [...state.images, ...accepted]));
    return picked.length - accepted.length;
  }

  void removeImage(int index) {
    final images = [...state.images]..removeAt(index);
    emit(state.copyWith(images: images));
  }

  Future<void> submit(AppUser reporter) async {
    if (state.isSubmitting) return;
    emit(state.copyWith(showErrors: true, clearError: true));
    if (!state.isValid) return;

    emit(state.copyWith(status: ReportFormStatus.submitting));
    try {
      final id = _incidents.newIncidentId();
      final prepared = await _photos.prepare(state.images);

      await _incidents.createIncident(
        photos: prepared.photos,
        Incident(
          id: id,
          title: state.title.trim(),
          description: state.description.trim(),
          category: state.category!,
          location: state.location!,
          photoCount: prepared.photos.length,
          thumbnail: prepared.thumbnail,
          reporterId: reporter.uid,
          reporterName: reporter.name,
          isAnonymous: state.isAnonymous,
        ),
      );

      if (!isClosed) {
        emit(
          state.copyWith(
            status: ReportFormStatus.success,
            createdIncidentId: id,
          ),
        );
      }
    } on PhotoTooLargeException catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: ReportFormStatus.failure,
            errorMessage: e.toString(),
          ),
        );
      }
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: ReportFormStatus.failure,
            errorMessage:
                'Could not submit your report. Check your connection '
                'and try again.',
          ),
        );
      }
    }
  }
}
