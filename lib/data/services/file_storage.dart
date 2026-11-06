import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants.dart';
import '../models/attachment.dart';

/// Uploads report files to Supabase Storage, one folder per incident, so
/// they can be browsed and previewed in the Supabase dashboard.
class FileStorage {
  /// Uses the app-wide client unless one is given (for tests).
  FileStorage([this._client]);

  final SupabaseClient? _client;

  StorageFileApi get _bucket => (_client ?? Supabase.instance.client).storage
      .from(AppConstants.storageBucket);

  Future<Attachment> upload(
    String incidentId,
    int index,
    NewAttachment file,
  ) async {
    final extension = file.isPdf ? 'pdf' : 'jpg';
    final path = '$incidentId/${index + 1}.$extension';
    await _bucket.uploadBinary(
      path,
      file.bytes,
      fileOptions: FileOptions(
        contentType: file.isPdf ? 'application/pdf' : 'image/jpeg',
      ),
    );
    return Attachment(
      url: _bucket.getPublicUrl(path),
      name: file.name,
      type: file.type,
    );
  }
}
