import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/pets/pet.dart';
import '../../providers/pets/pet_providers.dart';

class PetFormPage extends ConsumerStatefulWidget {
  const PetFormPage({super.key, this.existing});
  final Pet? existing;

  @override
  ConsumerState<PetFormPage> createState() => _PetFormPageState();
}

class _PetFormPageState extends ConsumerState<PetFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _type;
  late final TextEditingController _location;
  late final TextEditingController _description;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _type = TextEditingController(text: widget.existing?.type ?? '');
    _location = TextEditingController(text: widget.existing?.location ?? '');
    _description = TextEditingController(text: widget.existing?.description ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _type.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final addPet = ref.watch(addPetUseCaseProvider);
    final updatePet = ref.watch(updatePetUseCaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Add Pet' : 'Edit Pet'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _type,
                decoration: const InputDecoration(labelText: 'Type (dog/cat)'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _location,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 4,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitting
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;

                        setState(() => _submitting = true);

                        final now = DateTime.now();

                        final pet = Pet(
                          id: widget.existing?.id ?? '',
                          name: _name.text.trim(),
                          type: _type.text.trim().toLowerCase(),
                          location: _location.text.trim().isEmpty
                              ? null
                              : _location.text.trim(),
                          description: _description.text.trim().isEmpty
                              ? null
                              : _description.text.trim(),
                          ownerId: widget.existing?.ownerId ?? 'TODO_OWNER_ID',
                          createdAt: widget.existing?.createdAt ?? now,
                          updatedAt: now,
                          photoUrls: widget.existing?.photoUrls ?? const [],
                          isAdopted: widget.existing?.isAdopted ?? false,
                        );

                        try {
                          if (widget.existing == null) {
                            await addPet(pet);
                          } else {
                            await updatePet(pet);
                          }

                        
                          if (!context.mounted) return;

                          Navigator.pop(context);
                        } catch (e) {
                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed: $e')),
                          );
                        } finally {
                          if (mounted) setState(() => _submitting = false);
                        }
                      },
                child: Text(
                  _submitting ? 'Saving...' : (widget.existing == null ? 'Create' : 'Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
