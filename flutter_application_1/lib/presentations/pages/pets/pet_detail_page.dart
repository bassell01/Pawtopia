import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../providers/pets/pet_list_controller.dart';
import '../../providers/pets/pet_providers.dart';
import '../../widgets/pets/pet_card.dart';

final _petSearchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');

class PetListPage extends ConsumerStatefulWidget {
  const PetListPage({super.key});

  @override
  ConsumerState<PetListPage> createState() => _PetListPageState();
}

class _PetListPageState extends ConsumerState<PetListPage> {
  String? _type; // stored lowercase to match firestore
  bool _onlyAvailable = true;

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(_petSearchQueryProvider).trim().toLowerCase();

    final petsAsync = ref.watch(
      petsStreamProvider(
        PetsStreamFilter(type: _type, onlyAvailable: _onlyAvailable),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.petsTitle),
        actions: [
          IconButton(
            tooltip: _onlyAvailable ? 'Show all' : 'Show available only',
            onPressed: () => setState(() => _onlyAvailable = !_onlyAvailable),
            icon: Icon(_onlyAvailable ? Icons.check_circle : Icons.list),
          ),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(
            onChanged: (v) =>
                ref.read(_petSearchQueryProvider.notifier).state = v,
          ),
          _TypeFilterBar(
            onTypeChanged: (t) => setState(() => _type = t),
          ),
          Expanded(
            child: petsAsync.when(
              loading: () => const Center(child: LoadingIndicator()),
              error: (e, _) => Center(
                child: ErrorView(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(
                    petsStreamProvider(
                      PetsStreamFilter(type: _type, onlyAvailable: _onlyAvailable),
                    ),
                  ),
                ),
              ),
              data: (pets) {
                // client-side search filter (fast for small lists)
                final filtered = pets.where((p) {
                  if (query.isEmpty) return true;
                  final name = p.name.toLowerCase();
                  final type = p.type.toLowerCase();
                  final loc = (p.location ?? '').toLowerCase();
                  return name.contains(query) ||
                      type.contains(query) ||
                      loc.contains(query);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        AppStrings.noPetsFound,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final uiPets = filtered
                    .map(PetSummaryUiModel.fromEntity)
                    .toList();

                return RefreshIndicator(
                  onRefresh: () async {
                    // Stream refresh = invalidate provider
                    ref.invalidate(
                      petsStreamProvider(
                        PetsStreamFilter(type: _type, onlyAvailable: _onlyAvailable),
                      ),
                    );
                  },
                  child: ListView.separated(
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

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.sm,
        AppSizes.screenPadding,
        0,
      ),
      child: TextField(
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Search by name/type/location...',
          border: OutlineInputBorder(),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _TypeFilterBar extends StatefulWidget {
  const _TypeFilterBar({required this.onTypeChanged});
  final ValueChanged<String?> onTypeChanged;

  @override
  State<_TypeFilterBar> createState() => _TypeFilterBarState();
}

class _TypeFilterBarState extends State<_TypeFilterBar> {
  String _selected = 'All';
  final _types = const ['All', 'Dog', 'Cat', 'Bird', 'Other'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selected,
              decoration: const InputDecoration(labelText: 'Type'),
              items: _types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (value) {
                setState(() => _selected = value ?? 'All');
                final mapped = (_selected == 'All') ? null : _selected.toLowerCase();
                widget.onTypeChanged(mapped);
              },
            ),
          ),
        ],
      ),
    );
  }
}
