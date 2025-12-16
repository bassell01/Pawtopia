import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_sizes.dart';

import '../../providers/pets/pet_providers.dart';
import '../../providers/pets/pet_list_controller.dart';
import '../../widgets/pets/pet_card.dart';

class PetListPage extends ConsumerWidget {
  const PetListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petListState = ref.watch(petListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.petsTitle), // e.g. "Available Pets"
      ),
      body: Column(
        children: [
          const _PetFilterBar(),
          Expanded(
            child: petListState.when(
              loading: () => const Center(
                child: LoadingIndicator(),
              ),
              error: (err, stack) => Center(
                child: ErrorView(
                  message: err.toString(),
                  onRetry: () =>
                      ref.read(petListControllerProvider.notifier).refresh(),
                ),
              ),
              data: (pets) {
                if (pets.isEmpty) {
                  return Center(
                    child: Text(AppStrings.noPetsFound),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(petListControllerProvider.notifier)
                      .refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSizes.screenPadding),
                    itemBuilder: (context, index) {
                      final pet = pets[index];
                      return PetCard(
                        id: pet.id,
                        name: pet.name,
                        type: pet.type,
                        location: pet.location,
                        imageUrl: pet.thumbnailUrl,
                        isAdopted: pet.isAdopted,
                        onTap: () {
                          // TODO: navigate to pet_detail_page via app_router
                          // context.pushNamed(AppRoutes.petDetails, extra: pet.id);
                        },
                      );
                    },
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSizes.listItemSpacing),
                    itemCount: pets.length,
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
              initialValue: _selectedType ?? 'All',
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
                setState(() {
                  _selectedType = value;
                });

                final filterType =
                    (value == null || value == 'All') ? null : value;

                ref
                    .read(petListControllerProvider.notifier)
                    .applyTypeFilter(filterType?.toLowerCase());
              },
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          // Placeholder button – later you can open a full filter sheet
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
