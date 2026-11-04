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

/// Shrinks photos so they fit inside Firestore documents.
///
/// Photos are kept in Firestore rather than Cloud Storage because Storage
/// needs the paid Blaze plan; this keeps the app on the free Spark plan.
class PhotoRepository {
  /// Firestore documents are capped at 1 MiB; stay well under it.
  static const maxPhotoBytes = 700 * 1024;
  static const maxThumbnailBytes = 60 * 1024;

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
