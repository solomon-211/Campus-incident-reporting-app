import 'dart:typed_data';

import 'package:equatable/equatable.dart';

enum AttachmentType {
  image,
  pdf;

  static AttachmentType fromName(String? name) =>
      name == AttachmentType.pdf.name
      ? AttachmentType.pdf
      : AttachmentType.image;
}

/// A file uploaded with a report. The file itself lives in Supabase Storage;
/// Firestore keeps only its public link, name and type.
class Attachment extends Equatable {
  const Attachment({required this.url, required this.name, required this.type});

  final String url;
  final String name;
  final AttachmentType type;

  bool get isPdf => type == AttachmentType.pdf;

  factory Attachment.fromMap(Map<String, dynamic> map) => Attachment(
    url: map['url'] as String? ?? '',
    name: map['name'] as String? ?? '',
    type: AttachmentType.fromName(map['type'] as String?),
  );

  Map<String, dynamic> toMap() => {'url': url, 'name': name, 'type': type.name};

  @override
  List<Object?> get props => [url, name, type];
}

/// A file picked in the report form that hasn't been uploaded yet.
class NewAttachment extends Equatable {
  const NewAttachment({
    required this.name,
    required this.bytes,
    required this.type,
  });

  final String name;
  final Uint8List bytes;
  final AttachmentType type;

  bool get isPdf => type == AttachmentType.pdf;

  @override
  List<Object?> get props => [name, bytes, type];
}
