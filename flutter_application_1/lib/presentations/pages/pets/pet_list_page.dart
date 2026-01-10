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
import '../../widgets/pets/pet_card.dart';

import 'pet_form_page.dart';

class PetListPage extends ConsumerStatefulWidget {
  const PetListPage({super.key});

  @override
  ConsumerState<PetListPage> createState() => _PetListPageState();
}

class _PetListPageState extends ConsumerState<PetListPage> {
  String? _type;

  bool _onlyAvailable = true;
  bool _onlyMine = false;

  void _showUndoSnackBar(PetFormResult res) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final deletePet = ref.read(deletePetUseCaseProvider);
    final updatePet = ref.read(updatePetUseCaseProvider);

    if (res is PetCreatedResult) {
      final controller = messenger.showSnackBar(
        SnackBar(
          content: const Text('Pet added'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () async {
              try {
                await deletePet(res.createdPetId);
              } catch (_) {
                if (!mounted) return;
                messenger.hideCurrentSnackBar();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Undo failed'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        controller.close();
      });
    } else if (res is PetUpdatedResult) {
      final controller = messenger.showSnackBar(
        SnackBar(
          content: const Text('Pet updated'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () async {
              try {
                await updatePet(res.before);
              } catch (_) {
                if (!mounted) return;
                messenger.hideCurrentSnackBar();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Undo failed'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        controller.close();
      });
    }
  }

  Future<void> _openAddPet() async {
    final res = await context.push<PetFormResult>(AppRoutes.addPet);
    if (!mounted) return;
    if (res != null) _showUndoSnackBar(res);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final filter = PetsStreamFilter(type: _type, onlyAvailable: _onlyAvailable);
    final petsAsync = ref.watch(petsStreamProvider(filter));

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddPet,
        child: const Icon(Icons.add),
      ),
      body: CustomScrollView(
        slivers: [
          // ✅ AppBar hides on scroll down, reappears on scroll up
          SliverAppBar(
            title: Text(AppStrings.petsTitle),
            floating: true,
            snap: true,
            actions: const [], // ✅ no actions
          ),

          // ✅ Filter bar hides on scroll down, reappears on scroll up
          SliverPersistentHeader(
            floating: true,
            delegate: _FilterHeaderDelegate(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.screenPadding,
                  AppSizes.screenPadding,
                  AppSizes.screenPadding,
                  8,
                ),
                child: _PetFilterBar(
                  selectedType: _type,
                  onlyAvailable: _onlyAvailable,
                  onlyMine: _onlyMine,
                  onTypeChanged: (t) => setState(() => _type = t),
                  onOnlyAvailableChanged: (v) =>
                      setState(() => _onlyAvailable = v),
                  onOnlyMineChanged: (v) => setState(() => _onlyMine = v),
                ),
              ),
            ),
          ),

          // ✅ Content
          petsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: LoadingIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: ErrorView(
                message: e.toString(),
                onRetry: () => ref.invalidate(petsStreamProvider(filter)),
              ),
            ),
            data: (pets) {
              // ✅ Apply "My pets" filter in UI layer
              final filtered = (!_onlyMine || uid == null)
                  ? pets
                  : pets.where((p) => p.ownerId == uid).toList();

              final uiPets = filtered.map(PetSummaryUiModel.fromEntity).toList();

              if (uiPets.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      _onlyMine ? 'No pets owned by you' : AppStrings.noPetsFound,
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(AppSizes.screenPadding),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final pet = uiPets[i];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: i == uiPets.length - 1
                              ? 0
                              : AppSizes.listItemSpacing,
                        ),
                        child: PetCard(
                          id: pet.id,
                          name: pet.name,
                          type: pet.type,
                          location: pet.location,
                          imageUrl: pet.thumbnailUrl,
                          isAdopted: pet.isAdopted,
                          onTap: () async {
                            final res = await context.push<PetFormResult>(
                              AppRoutes.petDetails.replaceFirst(':id', pet.id),
                            );
                            if (!context.mounted) return;
                            if (res != null) _showUndoSnackBar(res);
                          },
                        ),
                      );
                    },
                    childCount: uiPets.length,
                  ),
                ),
              );
            },
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
    required this.onlyAvailable,
    required this.onOnlyAvailableChanged,
    required this.onlyMine,
    required this.onOnlyMineChanged,
  });

  final String? selectedType;
  final ValueChanged<String?> onTypeChanged;

  final bool onlyAvailable;
  final ValueChanged<bool> onOnlyAvailableChanged;

  final bool onlyMine;
  final ValueChanged<bool> onOnlyMineChanged;

  @override
  Widget build(BuildContext context) {
    final types = ['All', 'Dog', 'Cat', 'Bird', 'Other'];

    String dropdownValue() {
      if (selectedType == null) return 'All';
      return selectedType!.capitalize();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
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
        ),
        const SizedBox(width: 10),

        // Available checkbox
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: onlyAvailable,
                onChanged: (v) => onOnlyAvailableChanged(v ?? false),
              ),
              const Text('Available'),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Mine checkbox
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: onlyMine,
                onChanged: (v) => onOnlyMineChanged(v ?? false),
              ),
              const Text('Mine'),
            ],
          ),
        ),
      ],
    );
  }
}

/// ✅ Makes the filter bar a floating sliver that can hide/reappear with scroll.
class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  _FilterHeaderDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 72;

  @override
  double get maxExtent => 72;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: overlapsContent ? 2 : 0,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _FilterHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

extension on String {
  String capitalize() => isEmpty ? this : this[0].toUpperCase() + substring(1);
}
