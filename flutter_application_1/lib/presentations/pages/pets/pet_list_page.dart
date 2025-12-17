import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../providers/pets/pet_list_controller.dart';
import '../../providers/pets/pet_providers.dart';
import '../../widgets/pets/pet_card.dart';

class PetListPage extends ConsumerWidget {
  const PetListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(petsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.petsTitle),
      ),
      body: Column(
        children: [
          const _PetFilterBar(),
          Expanded(
            child: petsAsync.when(
              loading: () => const Center(child: LoadingIndicator()),
              error: (e, _) => Center(
                child: ErrorView(
                  message: e.toString(),
                  onRetry: () => ref.refresh(petsStreamProvider),
                ),
              ),
              data: (pets) {
                final uiPets =
                    pets.map(PetSummaryUiModel.fromEntity).toList();

                if (uiPets.isEmpty) {
                  return Center(child: Text(AppStrings.noPetsFound));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSizes.screenPadding),
                  itemCount: uiPets.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSizes.listItemSpacing),
                  itemBuilder: (context, i) => PetCard(
                    id: uiPets[i].id,
                    name: uiPets[i].name,
                    type: uiPets[i].type,
                    location: uiPets[i].location,
                    imageUrl: uiPets[i].thumbnailUrl,
                    isAdopted: uiPets[i].isAdopted,
                    onTap: () {
                      // TODO: navigate to pet details with id (router)
                      // Example: context.pushNamed(AppRoutes.petDetails, extra: uiPets[i].id);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PetFilterBar extends ConsumerStatefulWidget {
  const _PetFilterBar();

  @override
  ConsumerState<_PetFilterBar> createState() => _PetFilterBarState();
}

class _PetFilterBarState extends ConsumerState<_PetFilterBar> {
  String? _selectedType;

  final _types = <String>[
    'All',
    'Dog',
    'Cat',
    'Bird',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedType ?? 'All',
              decoration: const InputDecoration(
                labelText: 'Type',
              ),
              items: _types
                  .map(
                    (t) => DropdownMenuItem<String>(
                      value: t,
                      child: Text(t),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedType = value);

                // In the stream approach, filters should be passed to the stream provider.
                // For Week 2 baseline, we keep this UI only.
                // TODO: convert petsStreamProvider to a family provider with filters.
              },
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          IconButton(
            onPressed: () {
              // TODO: open advanced filter bottom sheet
            },
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
    );
  }
}
