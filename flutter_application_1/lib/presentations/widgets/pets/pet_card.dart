import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../favorites/favorite_icon_button.dart';
import '../../providers/favorites/favorites_provider.dart';

class PetCard extends StatelessWidget {
  const PetCard({
    super.key,
    required this.id,
    required this.name,
    required this.type,
    this.location,
    this.imageUrl,
    required this.isAdopted,
    this.onTap,
  });

  final String id;
  final String name;
  final String type;
  final String? location;
  final String? imageUrl;
  final bool isAdopted;
  final VoidCallback? onTap;

  bool _isHttpUrl(String url) {
    final t = url.trim().toLowerCase();
    return t.startsWith('http://') || t.startsWith('https://');
  }

  bool _isLocalFilePath(String url) {
    final t = url.trim().toLowerCase();
    return t.startsWith('/') || t.startsWith('file://') || t.contains(':/');
  }

  Widget _placeholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.pets),
    );
  }

  Widget _buildImage(BuildContext context) {
    final url = imageUrl;

    if (url == null || url.trim().isEmpty) {
      return _placeholder(context);
    }

    if (_isHttpUrl(url)) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(context),
      );
    }

    if (_isLocalFilePath(url)) {
      final file = url.trim().toLowerCase().startsWith('file://')
          ? File.fromUri(Uri.parse(url))
          : File(url);

      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(context),
      );
    }

    return _placeholder(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 100,
          child: Row(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: _buildImage(context),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        type,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          if (location != null && location!.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  location!,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          const Spacer(),
                          if (isAdopted)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'Adopted',
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              /// ❤️ Favorites count ABOVE heart icon
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Consumer(
                  builder: (context, ref, _) {
                    final countAsync = ref.watch(favoritesCountProvider(id));

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 🔢 COUNT (on top)
                        countAsync.when(
                          data: (count) {
                            // Hide when 0 for clean UI
                            if (count <= 0) return const SizedBox(height: 14);

                            return Text(
                              '$count',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            );
                          },
                          loading: () => const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          error: (_, __) => const SizedBox(height: 14),
                        ),

                        // Small spacing between number and heart
                        const SizedBox(height: 2),

                        // ❤️ HEART BUTTON
                        FavoriteIconButton(
                          petId: id,
                          activeColor: Colors.red,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
