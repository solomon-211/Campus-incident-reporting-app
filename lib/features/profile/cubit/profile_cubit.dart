import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/photo_compressor.dart';

/// Changes the profile picture. The state is true while a save is running;
/// the new picture itself arrives through the live profile in AuthCubit.
class ProfileCubit extends Cubit<bool> {
  ProfileCubit(this._auth, this._photos, {required this.uid}) : super(false);

  final AuthRepository _auth;
  final PhotoCompressor _photos;
  final String uid;

  /// Returns an error message, or null once saved.
  Future<String?> updatePhoto(Uint8List original) => _save(
    () async => _auth.updatePhoto(uid, await _photos.prepareAvatar(original)),
  );

  Future<String?> removePhoto() => _save(() => _auth.updatePhoto(uid, null));

  Future<String?> _save(Future<void> Function() action) async {
    if (state) return null;
    emit(true);
    try {
      await action();
      return null;
    } on PhotoTooLargeException catch (e) {
      return e.toString();
    } catch (_) {
      return 'Could not update your photo. Please try again.';
    } finally {
      if (!isClosed) emit(false);
    }
  }
}
