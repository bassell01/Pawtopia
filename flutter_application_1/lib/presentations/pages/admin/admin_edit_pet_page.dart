import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin/admin_providers.dart';

class AdminEditPetPage extends ConsumerStatefulWidget {
  final String petId;
  const AdminEditPetPage({super.key, required this.petId});

  @override
  ConsumerState<AdminEditPetPage> createState() => _AdminEditPetPageState();
}

class _AdminEditPetPageState extends ConsumerState<AdminEditPetPage> {
  final nameCtrl = TextEditingController();
  final typeCtrl = TextEditingController();
  final breedCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final genderCtrl = TextEditingController();
  final sizeCtrl = TextEditingController();
  final ageCtrl = TextEditingController();

  bool isAdopted = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final remote = ref.read(adminRemoteDataSourceProvider);
    final doc = await remote.getPetDoc(widget.petId);
    final data = doc.data() ?? {};

    nameCtrl.text = (data['name'] ?? '').toString();
    typeCtrl.text = (data['type'] ?? '').toString();
    breedCtrl.text = (data['breed'] ?? '').toString();
    locationCtrl.text = (data['location'] ?? '').toString();
    genderCtrl.text = (data['gender'] ?? '').toString();
    sizeCtrl.text = (data['size'] ?? '').toString();
    ageCtrl.text = (data['ageInMonths'] ?? '').toString();
    isAdopted = (data['isAdopted'] == true);

    setState(() => loading = false);
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    typeCtrl.dispose();
    breedCtrl.dispose();
    locationCtrl.dispose();
    genderCtrl.dispose();
    sizeCtrl.dispose();
    ageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remote = ref.read(adminRemoteDataSourceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Pet')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 12),
                TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Type')),
                const SizedBox(height: 12),
                TextField(controller: breedCtrl, decoration: const InputDecoration(labelText: 'Breed')),
                const SizedBox(height: 12),
                TextField(controller: genderCtrl, decoration: const InputDecoration(labelText: 'Gender')),
                const SizedBox(height: 12),
                TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Location')),
                const SizedBox(height: 12),
                TextField(controller: sizeCtrl, decoration: const InputDecoration(labelText: 'Size')),
                const SizedBox(height: 12),
                TextField(
                  controller: ageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Age (months)'),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Adopted'),
                  value: isAdopted,
                  onChanged: (v) => setState(() => isAdopted = v),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await remote.updatePetInfo(
                      petId: widget.petId,
                      data: {
                        'name': nameCtrl.text.trim(),
                        'type': typeCtrl.text.trim(),
                        'breed': breedCtrl.text.trim(),
                        'gender': genderCtrl.text.trim(),
                        'location': locationCtrl.text.trim(),
                        'size': sizeCtrl.text.trim(),
                        'ageInMonths': int.tryParse(ageCtrl.text.trim()) ?? 0,
                        'isAdopted': isAdopted,
                      },
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pet updated')));
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
    );
  }
}
