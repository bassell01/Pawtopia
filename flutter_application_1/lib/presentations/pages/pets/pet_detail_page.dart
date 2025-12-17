import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../providers/pets/pet_providers.dart';

class PetDetailPage extends ConsumerWidget {
  const PetDetailPage({super.key, required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petAsync = ref.watch(petDetailControllerProvider(petId));

    return Scaffold(
      appBar: AppBar(title: const Text('Pet Details')),
      body: petAsync.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (e, _) => Center(
          child: ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(petDetailControllerProvider(petId)),
          ),
        ),
        data: (pet) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: pet.photoUrls.isNotEmpty
                    ? Image.network(pet.photoUrls.first, fit: BoxFit.cover)
                    : const Center(child: Icon(Icons.pets, size: 48)),
              ),
              const SizedBox(height: 12),
              Text(pet.name,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text('${pet.type}${pet.breed != null ? " • ${pet.breed}" : ""}'),
              if (pet.location != null) ...[
                const SizedBox(height: 6),
                Text('Location: ${pet.location}'),
              ],
              const SizedBox(height: 12),
              Text(pet.description ?? 'No description'),
            ],
          );
        },
      ),
    );
  }
}
