import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/favorites/favorites_provider.dart';

class FavoriteIconButton extends ConsumerWidget {
  const FavoriteIconButton({
    super.key,
    required this.petId,
    this.activeColor = Colors.red,
  });

  final String petId;
  final Color activeColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavAsync = ref.watch(isFavoriteProvider(petId));
    final toggle = ref.watch(toggleFavoriteProvider);

    // 👇 Default to NOT favorite while loading/error
    final isFav = isFavAsync.maybeWhen(
      data: (v) => v,
      orElse: () => false,
    );

    return IconButton(
      tooltip: isFav ? 'Remove from favorites' : 'Add to favorites',
      icon: Icon(
        isFav ? Icons.favorite : Icons.favorite_border,
        color: isFav ? activeColor : null,
      ),
      onPressed: () => toggle(petId),
    );
  }
}
