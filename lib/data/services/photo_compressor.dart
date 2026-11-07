import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Thrown with a message that is safe to show to the user.
class PhotoTooLargeException implements Exception {
  const PhotoTooLargeException();

  @override
  String toString() =>
      'One of the photos is too large even after compression. '
      'Try a different photo.';
}

class PreparedPhotos {
  const PreparedPhotos({required this.photos, required this.thumbnail});

  final List<Uint8List> photos;
  final Uint8List? thumbnail;
}

/// Compresses photos on the device before they are uploaded or saved.
class PhotoCompressor {
  static const maxPhotoBytes = 700 * 1024;
  static const maxThumbnailBytes = 60 * 1024;
  static const maxAvatarBytes = 120 * 1024;

  /// (longest side, JPEG quality) steps tried until a photo fits.
  static const _steps = [(1280, 70), (1024, 55), (800, 45), (640, 40)];

  Future<PreparedPhotos> prepare(List<Uint8List> originals) async {
    if (originals.isEmpty) {
      return const PreparedPhotos(photos: [], thumbnail: null);
    }
    final photos = <Uint8List>[];
    for (final original in originals) {
      photos.add(await _compressToFit(original, maxPhotoBytes));
    }
    final thumbnail = await _compress(originals.first, 240, 60);
    return PreparedPhotos(
      photos: photos,
      thumbnail: thumbnail != null && thumbnail.length <= maxThumbnailBytes
          ? thumbnail
          : null,
    );
  }

  /// Square-ish profile picture, small enough to live on the user document.
  Future<Uint8List> prepareAvatar(Uint8List original) async {
    final result = await _compress(original, 320, 75);
    if (result != null && result.length <= maxAvatarBytes) return result;
    if (original.length <= maxAvatarBytes) return original;
    throw const PhotoTooLargeException();
  }

  Future<Uint8List> _compressToFit(Uint8List original, int limit) async {
    for (final (size, quality) in _steps) {
      final result = await _compress(original, size, quality);
      if (result == null) break; // Compression unsupported on this platform.
      if (result.length <= limit) return result;
    }
    if (original.length <= limit) return original;
    throw const PhotoTooLargeException();
  }

  Future<Uint8List?> _compress(Uint8List bytes, int size, int quality) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: size,
        minHeight: size,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      return result.isEmpty ? null : result;
    } catch (_) {
      return null;
    }
  }
}
