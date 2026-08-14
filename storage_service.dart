import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'supabase_service.dart';

/// Wraps uploads to a Supabase Storage bucket so widgets never call
/// `Supabase.instance.client.storage` directly.
///
/// Assumes a bucket named `post-images` exists (see README > Supabase
/// Setup). The bucket is public-read so `getPublicUrl` works directly;
/// if you switch it to private, swap `getPublicUrl` for
/// `createSignedUrl(path, expiresInSeconds)` instead.
class StorageService {
  final SupabaseClient _client = SupabaseService.client;
  static const String _bucket = 'post-images';
  final Uuid _uuid = const Uuid();

  /// Uploads [file] under `<ownerUid>/<uuid>.<ext>` and returns the public
  /// download URL. Throws on failure — callers must catch and show a
  /// non-crashing fallback UI per the Validation Rules.
  Future<String> uploadPostImage({
    required File file,
    required String ownerUid,
  }) async {
    final ext = file.path.split('.').last;
    final path = '$ownerUid/${_uuid.v4()}.$ext';

    await _client.storage.from(_bucket).upload(
          path,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    return _client.storage.from(_bucket).getPublicUrl(path);
  }
}
