import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';

import '../../providers/pets/pet_providers.dart';
import '../../providers/auth/auth_state_provider.dart';

import 'pet_form_page.dart';
import '../adoption/adoption_form_page.dart';

class PetDetailPage extends ConsumerWidget {
  const PetDetailPage({super.key, required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petAsync = ref.watch(petDetailControllerProvider(petId));
    final authAsync = ref.watch(authUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Details'),
        actions: [
          petAsync.maybeWhen(
            data: (pet) => IconButton(
              tooltip: 'Edit pet',
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PetFormPage(existing: pet)),
                );
              },
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: petAsync.maybeWhen(
        data: (pet) {
          // ✅ hide if already adopted
          if (pet.isAdopted == true) return const SizedBox.shrink();

          // ✅ wait auth to know who is user
          final me = authAsync.valueOrNull;
          if (me == null) return const SizedBox.shrink(); // not logged in

          // ✅ hide adopt button if user is owner
          if (me.uid == pet.ownerId) return const SizedBox.shrink();

          final firstPhoto = pet.photoUrls.isNotEmpty ? pet.photoUrls.first : null;

          return SizedBox(
            width: MediaQuery.of(context).size.width * 0.75,
            height: 52,
            child: FloatingActionButton.extended(
              onPressed: () async {
                final ok = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => AdoptionFormPage(
                      petId: pet.id,
                      ownerId: pet.ownerId,
                      petName: pet.name,
                      petType: pet.type,
                      petLocation: pet.location,
                      petPhotoUrl: firstPhoto,
                    ),
                  ),
                );

                // ✅ optional snack if returned success
                if (context.mounted && ok == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Request sent ✅')),
                  );
                }
              },
              icon: const Icon(Icons.volunteer_activism),
              label: const Text('Adopt'),
            ),
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),

      body: petAsync.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (pet) {
          final firstPhoto = pet.photoUrls.isNotEmpty ? pet.photoUrls.first : null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: firstPhoto != null
                    ? Image.network(firstPhoto, fit: BoxFit.cover)
                    : const Center(child: Icon(Icons.pets, size: 48)),
              ),
              const SizedBox(height: 12),
              Text(pet.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text('${pet.type}${pet.breed != null ? " • ${pet.breed}" : ""}'),
              if (pet.location != null) ...[
                const SizedBox(height: 6),
                Text('Location: ${pet.location}'),
              ],
              const SizedBox(height: 12),
              Text(pet.description ?? 'No description'),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }
}
