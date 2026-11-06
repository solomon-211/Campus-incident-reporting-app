import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants.dart';
import '../../../core/validators.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/attachment.dart';
import '../../../data/models/incident.dart';
import '../../../data/repositories/incident_repository.dart';
import '../../../data/services/photo_compressor.dart';

part 'report_form_state.dart';

class ReportFormCubit extends Cubit<ReportFormState> {
  ReportFormCubit(
    this._incidents,
    this._photos, {
    IncidentCategory? initialCategory,
  }) : super(ReportFormState(category: initialCategory));

  final IncidentRepository _incidents;
  final PhotoCompressor _photos;

  void setCategory(IncidentCategory category) =>
      emit(state.copyWith(category: category));

  void setTitle(String title) => emit(state.copyWith(title: title));

  void setDescription(String description) =>
      emit(state.copyWith(description: description));

  void setLocation(String location) => emit(state.copyWith(location: location));

  void setAnonymous(bool value) => emit(state.copyWith(isAnonymous: value));

  /// Adds photos or PDFs up to the limit. Returns how many were left out.
  int addFiles(List<NewAttachment> picked) {
    final room = AppConstants.maxAttachments - state.files.length;
    final accepted = picked.take(room).toList();
    emit(state.copyWith(files: [...state.files, ...accepted]));
    return picked.length - accepted.length;
  }

  void removeFile(int index) {
    final files = [...state.files]..removeAt(index);
    emit(state.copyWith(files: files));
  }

  /// Compresses the photos (PDFs are left as they are) and returns the files
  /// to upload, in the order they were picked, plus a thumbnail for lists.
  Future<(List<NewAttachment>, Uint8List?)> _prepareFiles() async {
    final images = state.files.where((f) => !f.isPdf).toList();
    final prepared = await _photos.prepare([for (final f in images) f.bytes]);
    var next = 0;
    final files = [
      for (final f in state.files)
        if (f.isPdf)
          f
        else
          NewAttachment(
            name: f.name,
            bytes: prepared.photos[next++],
            type: AttachmentType.image,
          ),
    ];
    return (files, prepared.thumbnail);
  }

  Future<void> submit(AppUser reporter) async {
    if (state.isSubmitting) return;
    emit(state.copyWith(showErrors: true, clearError: true));
    if (!state.isValid) return;

    emit(state.copyWith(status: ReportFormStatus.submitting));
    try {
      final id = _incidents.newIncidentId();
      final (files, thumbnail) = await _prepareFiles();

      await _incidents.createIncident(
        files: files,
        Incident(
          id: id,
          title: state.title.trim(),
          description: state.description.trim(),
          category: state.category!,
          location: state.location!,
          thumbnail: thumbnail,
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
    } on UploadFailure {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: ReportFormStatus.failure,
            errorMessage:
                'Could not upload your files. Check your connection '
                'and try again.',
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
