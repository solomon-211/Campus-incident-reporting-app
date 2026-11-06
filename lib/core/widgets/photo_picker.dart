import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme.dart';
import '../constants.dart';
import '../extensions.dart';

/// What the user picked in [showPhotoSourceSheet].
enum PhotoSourceChoice { camera, gallery, pdf, remove }

extension PhotoSourceChoiceSource on PhotoSourceChoice {
  ImageSource? get imageSource => switch (this) {
    PhotoSourceChoice.camera => ImageSource.camera,
    PhotoSourceChoice.gallery => ImageSource.gallery,
    PhotoSourceChoice.pdf || PhotoSourceChoice.remove => null,
  };
}

/// Bottom sheet offering camera or gallery, plus "Attach a PDF" when
/// [allowPdf] is set and "Remove photo" when [canRemove] is set. Returns
/// null if dismissed.
Future<PhotoSourceChoice?> showPhotoSourceSheet(
  BuildContext context, {
  bool allowPdf = false,
  bool canRemove = false,
}) {
  return showModalBottomSheet<PhotoSourceChoice>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(context, PhotoSourceChoice.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(context, PhotoSourceChoice.gallery),
          ),
          if (allowPdf)
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Attach a PDF'),
              onTap: () => Navigator.pop(context, PhotoSourceChoice.pdf),
            ),
          if (canRemove)
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.red,
              ),
              title: const Text(
                'Remove photo',
                style: TextStyle(color: AppColors.red),
              ),
              onTap: () => Navigator.pop(context, PhotoSourceChoice.remove),
            ),
        ],
      ),
    ),
  );
}

/// Opens the camera or gallery and returns the chosen photos as bytes:
/// up to [limit] from the gallery, one from the camera, empty if cancelled.
/// Shows a message if the picker can't open.
Future<List<Uint8List>> pickPhotos(
  BuildContext context,
  ImageSource source, {
  int limit = 1,
}) async {
  final picker = ImagePicker();
  final List<XFile> files;
  try {
    if (source == ImageSource.gallery && limit > 1) {
      files = await picker.pickMultiImage(limit: limit);
    } else {
      final file = await picker.pickImage(source: source);
      files = [?file];
    }
  } catch (_) {
    if (context.mounted) {
      context.showSnack('Could not open the camera or gallery.', error: true);
    }
    return const [];
  }
  return [for (final f in files) await f.readAsBytes()];
}

/// Lets the user choose one PDF and returns its name and bytes, or null if
/// cancelled, unreadable or over [AppConstants.maxPdfBytes].
Future<({String name, Uint8List bytes})?> pickPdf(BuildContext context) async {
  try {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    if (bytes.length > AppConstants.maxPdfBytes) {
      if (context.mounted) {
        context.showSnack('PDFs must be smaller than 10 MB.', error: true);
      }
      return null;
    }
    return (name: file.name, bytes: bytes);
  } catch (_) {
    if (context.mounted) {
      context.showSnack('Could not open that file.', error: true);
    }
    return null;
  }
}
