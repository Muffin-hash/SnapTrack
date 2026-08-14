/// Represents a single record created by a signed-in user, stored in the
/// Supabase `posts` table.
///
/// Extends the Week 3 database-backed model with two Week 4 additions:
/// an optional attached image (Supabase Storage public/signed URL) and an
/// optional attached location (lat/lng + a human-readable label).
class PostModel {
  final String id; // uuid, primary key, default in Postgres
  final String ownerUid; // auth.users.id (uuid)
  final String title;
  final String description;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final String? locationLabel;
  final DateTime createdAt;

  const PostModel({
    required this.id,
    required this.ownerUid,
    required this.title,
    required this.description,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.locationLabel,
    required this.createdAt,
  });

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasLocation => latitude != null && longitude != null;

  /// Builds a model from a row returned by `supabase.from('posts').select()`.
  factory PostModel.fromMap(Map<String, dynamic> row) {
    return PostModel(
      id: row['id'] as String,
      ownerUid: row['owner_uid'] as String? ?? '',
      title: row['title'] as String? ?? '',
      description: row['description'] as String? ?? '',
      imageUrl: row['image_url'] as String?,
      latitude: (row['latitude'] as num?)?.toDouble(),
      longitude: (row['longitude'] as num?)?.toDouble(),
      locationLabel: row['location_label'] as String?,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Builds the payload for an insert/update. `id` and `created_at` are
  /// left to Postgres defaults on insert, so they're excluded here.
  Map<String, dynamic> toInsertMap() {
    return {
      'owner_uid': ownerUid,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'location_label': locationLabel,
    };
  }

  PostModel copyWith({
    String? imageUrl,
    double? latitude,
    double? longitude,
    String? locationLabel,
  }) {
    return PostModel(
      id: id,
      ownerUid: ownerUid,
      title: title,
      description: description,
      imageUrl: imageUrl ?? this.imageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationLabel: locationLabel ?? this.locationLabel,
      createdAt: createdAt,
    );
  }
}
