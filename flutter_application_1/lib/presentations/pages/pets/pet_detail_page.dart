import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';

import '../../providers/pets/pet_providers.dart';
import 'pet_form_page.dart';

class PetDetailPage extends ConsumerWidget {
  const PetDetailPage({super.key, required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petAsync = ref.watch(petDetailControllerProvider(petId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Details'),
        actions: [
          // ✅ Edit button (always visible once pet is loaded)
          petAsync.maybeWhen(
            data: (pet) => IconButton(
              tooltip: 'Edit pet',
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PetFormPage(existing: pet),
                  ),
                );
              },
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),

      // ✅ Center floating Adopt button
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: petAsync.maybeWhen(
        data: (pet) {
          // Optional: hide button if already adopted
          if (pet.isAdopted == true) {
            return const SizedBox.shrink();
          }

          return SizedBox(
            width: MediaQuery.of(context).size.width * 0.75,
            height: 52,
            child: FloatingActionButton.extended(
              onPressed: () {
                final messenger = ScaffoldMessenger.of(context);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Adopt request for: ${pet.name} (petId=$petId)'),
                  ),
                );
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
              Text(pet.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text('${pet.type}${pet.breed != null ? " • ${pet.breed}" : ""}'),
              if (pet.location != null) ...[
                const SizedBox(height: 6),
                Text('Location: ${pet.location}'),
              ],
              const SizedBox(height: 12),
              Text(pet.description ?? 'No description'),

              const SizedBox(height: 80), // ✅ space so button doesn't cover content
            ],
          );
        },
      ),
    );
  }
}
