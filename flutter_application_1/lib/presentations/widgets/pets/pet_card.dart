import 'dart:io';

import 'package:flutter/material.dart';

import '../favorites/favorite_icon_button.dart';

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
    // Common local cases:
    // /data/user/0/...  (Android)
    // file:///data/user/0/...
    // C:\... (Windows dev)
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

    // ✅ If it is a normal web URL (Firebase Storage download URL, CDN, etc.)
    if (_isHttpUrl(url)) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        // ✅ If the URL fails (e.g., 403), don’t crash — show placeholder
        errorBuilder: (_, __, ___) => _placeholder(context),
      );
    }

    // ✅ If it is a local file path
    if (_isLocalFilePath(url)) {
      // Handle file:// URIs by converting to File safely
      final file = url.trim().toLowerCase().startsWith('file://')
          ? File.fromUri(Uri.parse(url))
          : File(url);

      return Image.file(
        file,
        fit: BoxFit.cover,
        // ✅ If the file doesn’t exist anymore, don’t crash
        errorBuilder: (_, __, ___) => _placeholder(context),
      );
    }

    // ✅ Anything else (like gs://...) -> we can’t display directly
    // It must be converted to an https download URL before UI can show it.
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

              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FavoriteIconButton(
                  petId: id,
                  activeColor: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
