import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';

import '../../providers/pets/pet_list_controller.dart';
import '../../providers/pets/pet_providers.dart';
import '../../providers/profile/profile_providers.dart';
import '../../widgets/pets/pet_card.dart';

import '../../../domain/entities/auth/user.dart' show UserRole;
import '../../providers/auth/auth_providers.dart';

class PetListPage extends ConsumerStatefulWidget {
  const PetListPage({super.key});

  @override
  ConsumerState<PetListPage> createState() => _PetListPageState();
}

class _PetListPageState extends ConsumerState<PetListPage> {
  String? _type;
  bool _onlyAvailable = true;

  @override
  Widget build(BuildContext context) {
    final filter = PetsStreamFilter(type: _type, onlyAvailable: _onlyAvailable);

    final petsAsync = ref.watch(petsStreamProvider(filter));

    final authState = ref.watch(authControllerProvider);
    final u = authState.user;

    final canAddPets =
        u != null && (u.role == UserRole.shelter || u.role == UserRole.admin);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.petsTitle),
        actions: [
          IconButton(
            tooltip: _onlyAvailable ? 'Show all pets' : 'Show available only',
            icon: Icon(_onlyAvailable ? Icons.check_circle : Icons.list),
            onPressed: () => setState(() => _onlyAvailable = !_onlyAvailable),
          ),
        ],
      ),

      // ✅ FAB visible only for shelter/admin
      floatingActionButton: canAddPets
          ? FloatingActionButton(
              onPressed: () => context.push(AppRoutes.addPet),
              child: const Icon(Icons.add),
            )
          : null,

      body: Column(
        children: [
          _PetFilterBar(
            selectedType: _type,
            onTypeChanged: (t) => setState(() => _type = t),
          ),
          Expanded(
            child: petsAsync.when(
              loading: () => const Center(child: LoadingIndicator()),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () => ref.invalidate(petsStreamProvider(filter)),
              ),
              data: (pets) {
                final uiPets = pets.map(PetSummaryUiModel.fromEntity).toList();

                if (uiPets.isEmpty) {
                  return Center(child: Text(AppStrings.noPetsFound));
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(petsStreamProvider(filter));
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSizes.screenPadding),
                    itemCount: uiPets.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSizes.listItemSpacing),
                    itemBuilder: (context, i) => PetCard(
                      id: uiPets[i].id,
                      name: uiPets[i].name,
                      type: uiPets[i].type,
                      location: uiPets[i].location,
                      imageUrl: uiPets[i].thumbnailUrl,
                      isAdopted: uiPets[i].isAdopted,
                      onTap: () {
                        context.push(
                          AppRoutes.petDetails.replaceFirst(
                            ':id',
                            uiPets[i].id,
                          ),
                        );
                      },
                    ),
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

class _PetFilterBar extends StatelessWidget {
  const _PetFilterBar({
    required this.selectedType,
    required this.onTypeChanged,
  });

  final String? selectedType;
  final ValueChanged<String?> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    final types = ['All', 'Dog', 'Cat', 'Bird', 'Other'];

    String dropdownValue() {
      if (selectedType == null) return 'All';
      return selectedType!.capitalize();
    }

    return Padding(
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      child: DropdownButtonFormField<String>(
        // Flutter 3.33+ ✅
        initialValue: dropdownValue(),
        decoration: const InputDecoration(labelText: 'Type'),
        items: types
            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
            .toList(),
        onChanged: (value) {
          if (value == null || value == 'All') {
            onTypeChanged(null);
          } else {
            onTypeChanged(value.toLowerCase());
          }
        },
      ),
    );
  }
}

extension on String {
  String capitalize() => isEmpty ? this : this[0].toUpperCase() + substring(1);
}
