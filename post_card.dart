import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/post_model.dart';

/// Renders a single post's image (if any) and location (if any) alongside
/// its title/description. Used in the home list and detail screen.
class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onTap;

  const PostCard({super.key, required this.post, this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat.yMMMd().add_jm().format(post.createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.hasImage)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  post.imageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stack) => const ColoredBox(
                    color: Colors.black12,
                    child: Center(child: Icon(Icons.broken_image_outlined)),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(post.description, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  if (post.hasLocation)
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            post.locationLabel ??
                                '${post.latitude!.toStringAsFixed(4)}, '
                                    '${post.longitude!.toStringAsFixed(4)}',
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Text(dateLabel, style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
