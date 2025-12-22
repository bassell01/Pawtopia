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
  late final TextEditingController _breed;
  late final TextEditingController _ageInMonths;
  late final TextEditingController _description;
  late final TextEditingController _location;
  late final TextEditingController _photoUrls; // comma/newline separated
  late final TextEditingController _ownerId;

  String? _gender; // male/female
  String? _size; // small/medium/large
  bool _isAdopted = false;

  @override
  void initState() {
    super.initState();

    final p = widget.existing;

    _name = TextEditingController(text: p?.name ?? '');
    _type = TextEditingController(text: p?.type ?? '');
    _breed = TextEditingController(text: p?.breed ?? '');
    _ageInMonths =
        TextEditingController(text: p?.ageInMonths?.toString() ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _location = TextEditingController(text: p?.location ?? '');
    _photoUrls = TextEditingController(text: (p?.photoUrls ?? const []).join('\n'));
    _ownerId = TextEditingController(text: p?.ownerId ?? '');

    _gender = p?.gender;
    _size = p?.size;
    _isAdopted = p?.isAdopted ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _type.dispose();
    _breed.dispose();
    _ageInMonths.dispose();
    _description.dispose();
    _location.dispose();
    _photoUrls.dispose();
    _ownerId.dispose();
    super.dispose();
  }

  List<String> _parsePhotoUrls(String raw) {
    final parts = raw
        .split(RegExp(r'[\n,]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return parts;
  }

  int? _parseIntOrNull(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final existing = widget.existing;

    final typeLower = _type.text.trim().toLowerCase();

    final ownerId = _ownerId.text.trim().isEmpty
        ? (existing?.ownerId ?? 'TODO_OWNER_ID')
        : _ownerId.text.trim();

    final pet = Pet(
      id: existing?.id ?? '',
      name: _name.text.trim(),
      type: typeLower,
      breed: _breed.text.trim().isEmpty ? null : _breed.text.trim(),
      ageInMonths: _parseIntOrNull(_ageInMonths.text),
      gender: (_gender == null || _gender!.trim().isEmpty) ? null : _gender,
      size: (_size == null || _size!.trim().isEmpty) ? null : _size,
      description:
          _description.text.trim().isEmpty ? null : _description.text.trim(),
      location: _location.text.trim().isEmpty ? null : _location.text.trim(),
      photoUrls: _parsePhotoUrls(_photoUrls.text),
      isAdopted: _isAdopted,
      ownerId: ownerId,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      final addPet = ref.read(addPetUseCaseProvider);
      final updatePet = ref.read(updatePetUseCaseProvider);

      if (existing == null) {
        await addPet(pet);
      } else {
        await updatePet(pet);
      }

      if (!context.mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save pet: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Pet' : 'Add Pet'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _type,
                decoration:
                    const InputDecoration(labelText: 'Type (dog/cat) *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _breed,
                decoration: const InputDecoration(labelText: 'Breed (optional)'),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _ageInMonths,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Age in months (optional)',
                  hintText: 'e.g. 6',
                ),
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return null;
                  final n = int.tryParse(t);
                  if (n == null || n < 0) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: (_gender == null || _gender!.isEmpty)
                    ? null
                    : _gender,
                decoration: const InputDecoration(labelText: 'Gender (optional)'),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                ],
                onChanged: (v) => setState(() => _gender = v),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue:
                    (_size == null || _size!.isEmpty) ? null : _size,
                decoration: const InputDecoration(labelText: 'Size (optional)'),
                items: const [
                  DropdownMenuItem(value: 'small', child: Text('Small')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'large', child: Text('Large')),
                ],
                onChanged: (v) => setState(() => _size = v),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _location,
                decoration:
                    const InputDecoration(labelText: 'Location (optional)'),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _description,
                decoration:
                    const InputDecoration(labelText: 'Description (optional)'),
                maxLines: 4,
              ),
              const SizedBox(height: 12),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isAdopted,
                onChanged: (v) => setState(() => _isAdopted = v),
                title: const Text('Mark as adopted'),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _photoUrls,
                decoration: const InputDecoration(
                  labelText: 'Photo URLs (optional)',
                  hintText: 'One per line or separated by commas',
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _ownerId,
                decoration: const InputDecoration(
                  labelText: 'Owner ID (required)',
                  hintText: 'Shelter/individual userId',
                ),
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (widget.existing != null) return null; // keep existing ok
                  // For new pets, if left empty we fallback to TODO_OWNER_ID,
                  // but warn to encourage correct data.
                  if (value.isEmpty) {
                    return 'Owner ID is required (enter your uid for now)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _submit,
                child: Text(isEdit ? 'Save' : 'Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
