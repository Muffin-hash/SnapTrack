import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post_model.dart';
import 'supabase_service.dart';

/// Wraps all reads/writes to the `posts` table so screens never call
/// `Supabase.instance.client.from(...)` directly.
///
/// Expected schema (see README > Supabase Setup for the full SQL):
///   posts (
///     id            uuid primary key default gen_random_uuid(),
///     owner_uid     uuid not null references auth.users(id),
///     title         text not null,
///     description   text not null default '',
///     image_url     text,
///     latitude      double precision,
///     longitude     double precision,
///     location_label text,
///     created_at    timestamptz not null default now()
///   )
class DatabaseService {
  final SupabaseClient _client = SupabaseService.client;
  static const String _table = 'posts';

  /// Realtime stream of the signed-in user's posts, newest first.
  /// Mirrors the Week 3 StreamBuilder pattern but backed by Supabase's
  /// realtime channel instead of a Firestore snapshot listener.
  Stream<List<PostModel>> watchMyPosts(String ownerUid) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('owner_uid', ownerUid)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(PostModel.fromMap).toList());
  }

  Future<PostModel> createPost({
    required String ownerUid,
    required String title,
    required String description,
  }) async {
    final draft = PostModel(
      id: '',
      ownerUid: ownerUid,
      title: title,
      description: description,
      createdAt: DateTime.now(),
    );
    final row = await _client
        .from(_table)
        .insert(draft.toInsertMap())
        .select()
        .single();
    return PostModel.fromMap(row);
  }

  Future<void> attachImageUrl(String postId, String imageUrl) async {
    await _client.from(_table).update({'image_url': imageUrl}).eq('id', postId);
  }

  Future<void> attachLocation({
    required String postId,
    required double latitude,
    required double longitude,
    String? locationLabel,
  }) async {
    await _client.from(_table).update({
      'latitude': latitude,
      'longitude': longitude,
      'location_label': locationLabel,
    }).eq('id', postId);
  }

  Future<void> deletePost(String postId) async {
    await _client.from(_table).delete().eq('id', postId);
  }
}
