import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/admin/admin_providers.dart';
import 'admin_edit_pet_page.dart';

class AdminManagePetsPage extends ConsumerStatefulWidget {
  const AdminManagePetsPage({super.key});

  @override
  ConsumerState<AdminManagePetsPage> createState() => _AdminManagePetsPageState();
}

class _AdminManagePetsPageState extends ConsumerState<AdminManagePetsPage> {
  static const filters = ['all', 'available', 'adopted'];
  String filter = 'all';
  String query = '';

  // ✅ cache owner names to avoid re-fetching
  final Map<String, String> _ownerNameCache = {};

  Future<String?> _getOwnerName(String ownerId) async {
    if (ownerId.isEmpty) return null;
    if (_ownerNameCache.containsKey(ownerId)) return _ownerNameCache[ownerId];

    final remote = ref.read(adminRemoteDataSourceProvider);
    final name = await remote.getUserNameById(ownerId);

    if (name != null && name.isNotEmpty) {
      _ownerNameCache[ownerId] = name;
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final remote = ref.watch(adminRemoteDataSourceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Pets')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search by name/breed/type',
                    ),
                    onChanged: (v) => setState(() => query = v.trim().toLowerCase()),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: filter,
                  items: filters.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (v) => setState(() => filter = v ?? 'all'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: remote.petsStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));

                var docs = snap.data?.docs ?? [];

                docs = docs.where((d) {
                  final data = d.data();
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final breed = (data['breed'] ?? '').toString().toLowerCase();
                  final type = (data['type'] ?? '').toString().toLowerCase();
                  final isAdopted = (data['isAdopted'] == true);

                  final matchQuery = 
                      query.isEmpty ||
                      name.contains(query) ||
                      breed.contains(query) ||
                      type.contains(query);

                  final matchFilter =
                      filter == 'all' ||
                      (filter == 'available' && !isAdopted) ||
                      (filter == 'adopted' && isAdopted);

                  return matchQuery && matchFilter;
                }).toList();

                if (docs.isEmpty) return const Center(child: Text('No pets found.'));

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final d = docs[i];
                    final data = d.data();
                    final petId = d.id;

                    final name = (data['name'] ?? 'Pet').toString();
                    final type = (data['type'] ?? '').toString();
                    final breed = (data['breed'] ?? '').toString();
                    final gender = (data['gender'] ?? '').toString();
                    final location = (data['location'] ?? '').toString();
                    final age = data['ageInMonths'];
                    final size = (data['size'] ?? '').toString();
                    final ownerId = (data['ownerId'] ?? '').toString();
                    final isAdopted = (data['isAdopted'] == true);

                    final photos = (data['photoUrls'] is List)
                        ? List<String>.from(data['photoUrls'])
                        : <String>[];
                    final photo = photos.isNotEmpty ? photos.first : null;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 72,
                                height: 72,
                                color: Colors.black12,
                                child: photo == null
                                    ? const Icon(Icons.pets, size: 32)
                                    : Image.network(
                                        photo,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.broken_image),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      if (type.isNotEmpty) Chip(label: Text(type)),
                                      if (breed.isNotEmpty) Chip(label: Text(breed)),
                                      if (gender.isNotEmpty) Chip(label: Text(gender)),
                                      if (age != null) Chip(label: Text('${age}m')),
                                      if (size.isNotEmpty) Chip(label: Text(size)),
                                      Chip(label: Text(isAdopted ? 'Adopted' : 'Available')),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  if (location.isNotEmpty) Text('📍 $location'),

                                  // ✅ Owner name instead of ownerId
                                  if (ownerId.isNotEmpty)
                                    FutureBuilder<String?>(
                                      future: _getOwnerName(ownerId),
                                      builder: (context, ownerSnap) {
                                        final ownerName = ownerSnap.data;
                                        if (ownerSnap.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Text('Owner: loading...');
                                        }
                                        return Text(
                                          'Owner: ${ownerName?.isNotEmpty == true ? ownerName : 'Unknown'}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                  tooltip: 'Toggle Adopted',
                                  icon: Icon(isAdopted ? Icons.undo : Icons.done),
                                  onPressed: () async {
                                    await remote.setPetAdopted(
                                      petId: petId,
                                      isAdopted: !isAdopted,
                                    );
                                  },
                                ),
                                IconButton(
                                  tooltip: 'Edit',
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AdminEditPetPage(petId: petId),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  icon: const Icon(Icons.delete),
                                  onPressed: () async {
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Delete pet?'),
                                        content: const Text(
                                            'This will permanently delete the pet.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (ok == true) await remote.deletePet(petId);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
