import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../domain/entities/pets/pet.dart';
import '../../providers/pets/pet_providers.dart';
import '../../providers/auth/auth_state_provider.dart';

/// ✅ Result types live in the SAME file (no new folders/files)
sealed class PetFormResult {
  const PetFormResult();
}

class PetCreatedResult extends PetFormResult {
  const PetCreatedResult({required this.createdPetId, required this.pet});
  final String createdPetId;
  final Pet pet;
}

class PetUpdatedResult extends PetFormResult {
  const PetUpdatedResult({required this.before, required this.after});
  final Pet before;
  final Pet after;
}

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
    _ageInMonths = TextEditingController(text: p?.ageInMonths?.toString() ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _location = TextEditingController(text: p?.location ?? '');
    _photoUrls = TextEditingController(text: (p?.photoUrls ?? const []).join('\n'));

    _gender = p?.gender;
    _size = p?.size;
    _isAdopted = p?.isAdopted ?? false;

    // ✅ So preview updates when user types
    _photoUrls.addListener(() {
      if (mounted) setState(() {});
    });
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
    super.dispose();
  }

  List<String> _parsePhotoUrls(String raw) {
    return raw
        .split(RegExp(r'[\n,]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  int? _parseIntOrNull(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  bool _isHttpUrl(String url) {
    final t = url.trim().toLowerCase();
    return t.startsWith('http://') || t.startsWith('https://');
  }

  bool _isLocalFilePath(String url) {
    final t = url.trim().toLowerCase();
    return t.startsWith('/') || t.startsWith('file://') || t.contains(':/');
  }

  Widget _placeholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: const Icon(Icons.pets, size: 42),
    );
  }

  Widget _smartImage(BuildContext context, String raw) {
    final url = raw.trim();
    if (url.isEmpty) return _placeholder(context);

    if (_isHttpUrl(url)) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => _placeholder(context),
      );
    }

    if (_isLocalFilePath(url)) {
      final file = url.toLowerCase().startsWith('file://')
          ? File.fromUri(Uri.parse(url))
          : File(url);

      return Image.file(
        file,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => _placeholder(context),
      );
    }

    return _placeholder(context);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // ✅ Auth check (to set ownerId correctly)
    final authState = ref.read(authUserProvider);
    final user = authState.value;

    if (authState.isLoading) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading user...')),
      );
      return;
    }

    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first.')),
      );
      return;
    }

    final now = DateTime.now();
    final existing = widget.existing;

    final typeLower = _type.text.trim().toLowerCase();

    final pet = Pet(
      id: existing?.id ?? '',
      name: _name.text.trim(),
      type: typeLower,
      breed: _breed.text.trim().isEmpty ? null : _breed.text.trim(),
      ageInMonths: _parseIntOrNull(_ageInMonths.text),
      gender: (_gender == null || _gender!.trim().isEmpty) ? null : _gender,
      size: (_size == null || _size!.trim().isEmpty) ? null : _size,
      description: _description.text.trim().isEmpty ? null : _description.text.trim(),
      location: _location.text.trim().isEmpty ? null : _location.text.trim(),
      photoUrls: _parsePhotoUrls(_photoUrls.text),
      isAdopted: _isAdopted,
      ownerId: widget.existing?.ownerId ?? user.uid,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      final addPet = ref.read(addPetUseCaseProvider); // Future<String> Function(Pet)
      final updatePet = ref.read(updatePetUseCaseProvider);

      if (existing == null) {
        final createdId = await addPet(pet);

        if (!context.mounted) return;
        Navigator.of(context).pop(
          PetCreatedResult(createdPetId: createdId, pet: pet),
        );
      } else {
        await updatePet(pet);

        if (!context.mounted) return;
        Navigator.of(context).pop(
          PetUpdatedResult(before: existing, after: pet),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save pet: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    final photos = _parsePhotoUrls(_photoUrls.text);

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
                decoration: const InputDecoration(labelText: 'Type (dog/cat) *'),
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
                initialValue: (_gender == null || _gender!.isEmpty) ? null : _gender,
                decoration: const InputDecoration(labelText: 'Gender (optional)'),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                ],
                onChanged: (v) => setState(() => _gender = v),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: (_size == null || _size!.isEmpty) ? null : _size,
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
                decoration: const InputDecoration(labelText: 'Location (optional)'),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
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

              const SizedBox(height: 16),
              Text('Preview', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),

              if (photos.isEmpty)
                const Text('No photos yet. Paste one or more URLs above.')
              else ...[
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _smartImage(context, photos.first),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(photos.length, (i) {
                    final p = photos[i];
                    return InputChip(
                      label: Text(_isHttpUrl(p) ? 'URL ${i + 1}' : 'Photo ${i + 1}'),
                      onDeleted: () {
                        final next = List<String>.from(photos)..removeAt(i);
                        _photoUrls.text = next.join('\n');
                      },
                    );
                  }),
                ),
              ],

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
