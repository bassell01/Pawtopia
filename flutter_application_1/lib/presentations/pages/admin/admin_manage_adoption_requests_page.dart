import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/admin/admin_providers.dart';

class AdminManageAdoptionRequestsPage extends ConsumerStatefulWidget {
  const AdminManageAdoptionRequestsPage({super.key});

  @override
  ConsumerState<AdminManageAdoptionRequestsPage> createState() =>
      _AdminManageAdoptionRequestsPageState();
}

class _AdminManageAdoptionRequestsPageState
    extends ConsumerState<AdminManageAdoptionRequestsPage> {
  //Tabs you want
  static const _tabStatuses = ['pending', 'approved', 'cancelled', 'rejected'];
  static const _tabTitles = ['Pending', 'Accepted', 'Cancelled', 'Rejected'];

  DateTime? fromDate;
  DateTime? toDate;

  //cache to avoid refetching per rebuild
  final Map<String, Map<String, dynamic>> _usersCache = {};
  final Map<String, Map<String, dynamic>> _petsCache = {};

  Future<Map<String, dynamic>?> _getUser(String uid) async {
    if (uid.isEmpty) return null;
    if (_usersCache.containsKey(uid)) return _usersCache[uid];

    final remote = ref.read(adminRemoteDataSourceProvider);
    final data = await remote.getUserById(uid);
    if (data != null) _usersCache[uid] = data;
    return data;
  }

  Future<Map<String, dynamic>?> _getPet(String petId) async {
    if (petId.isEmpty) return null;
    if (_petsCache.containsKey(petId)) return _petsCache[petId];

    final remote = ref.read(adminRemoteDataSourceProvider);
    final data = await remote.getPetById(petId);
    if (data != null) _petsCache[petId] = data;
    return data;
  }

  DateTime? _toDateTime(dynamic ts) {
    if (ts is Timestamp) return ts.toDate();
    return null;
  }

  bool _inDateRange(DateTime? created) {
    if (created == null) return true;
    if (fromDate != null &&
        created.isBefore(
          DateTime(fromDate!.year, fromDate!.month, fromDate!.day),
        )) {
      return false;
    }
    if (toDate != null) {
      final end = DateTime(
        toDate!.year,
        toDate!.month,
        toDate!.day,
        23,
        59,
        59,
      );
      if (created.isAfter(end)) return false;
    }
    return true;
  }

  String _prettyDate(DateTime d) {
    // simple readable format
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => fromDate = picked);
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => toDate = picked);
  }

  void _clearDates() {
    setState(() {
      fromDate = null;
      toDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final remote = ref.watch(adminRemoteDataSourceProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Adoption Requests'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Accepted'),
              Tab(text: 'Cancelled'),
              Tab(text: 'Rejected'),
            ],
          ),
        ),
        body: Column(
          children: [
            // ✅ Date filter row
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickFromDate,
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      fromDate == null
                          ? 'From'
                          : '${fromDate!.year}-${fromDate!.month}-${fromDate!.day}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _pickToDate,
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      toDate == null
                          ? 'To'
                          : '${toDate!.year}-${toDate!.month}-${toDate!.day}',
                    ),
                  ),
                  const Spacer(),
                  if (fromDate != null || toDate != null)
                    TextButton(
                      onPressed: _clearDates,
                      child: const Text('Clear'),
                    ),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: remote.adoptionRequestsStream(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Error: ${snap.error}'));
                  }

                  final all = snap.data?.docs ?? [];

                  return TabBarView(
                    children: List.generate(4, (tabIndex) {
                      final status = _tabStatuses[tabIndex];

                      final docs = all.where((d) {
                        final data = d.data();
                        final st = (data['status'] ?? 'pending').toString();
                        if (st != status) return false;

                        final created = _toDateTime(data['createdAt']);
                        return _inDateRange(created);
                      }).toList();

                      if (docs.isEmpty) {
                        return const Center(child: Text('No requests'));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: docs.length,
                        itemBuilder: (context, i) {
                          final d = docs[i];
                          final data = d.data();

                          final petId = (data['petId'] ?? '').toString();
                          final requesterId =
                              (data['requesterId'] ?? data['userId'] ?? '')
                                  .toString();
                          final ownerId = (data['ownerId'] ?? '').toString();
                          final created = _toDateTime(data['createdAt']);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: FutureBuilder<List<Map<String, dynamic>?>>(
                                future: Future.wait([
                                  _getPet(petId),
                                  _getUser(requesterId),
                                  _getUser(ownerId),
                                ]),
                                builder: (context, snap2) {
                                  final pet = snap2.data != null
                                      ? snap2.data![0]
                                      : null;
                                  final requester = snap2.data != null
                                      ? snap2.data![1]
                                      : null;
                                  final owner = snap2.data != null
                                      ? snap2.data![2]
                                      : null;

                                  final petName = (pet?['name'] ?? 'Pet')
                                      .toString();
                                  final petType = (pet?['type'] ?? '')
                                      .toString();
                                  final petBreed = (pet?['breed'] ?? '')
                                      .toString();
                                  final petGender = (pet?['gender'] ?? '')
                                      .toString();
                                  final photos = (pet?['photoUrls'] is List)
                                      ? List<String>.from(pet?['photoUrls'])
                                      : <String>[];
                                  final photo = photos.isNotEmpty
                                      ? photos.first
                                      : null;

                                  final requesterName =
                                      (requester?['name'] ??
                                              requester?['fullName'] ??
                                              '')
                                          .toString();
                                  final requesterEmail =
                                      (requester?['email'] ?? '').toString();

                                  final ownerName =
                                      (owner?['name'] ??
                                              owner?['fullName'] ??
                                              'Owner')
                                          .toString();
                                  final ownerEmail = (owner?['email'] ?? '')
                                      .toString();

                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                                      const Icon(
                                                        Icons.broken_image,
                                                      ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${_tabTitles[tabIndex]} Request',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 6),

                                            Text(
                                              'Pet: $petName'
                                              '${petType.isNotEmpty ? ' • $petType' : ''}'
                                              '${petBreed.isNotEmpty ? ' • $petBreed' : ''}'
                                              '${petGender.isNotEmpty ? ' • $petGender' : ''}',
                                            ),

                                            const SizedBox(height: 6),
                                            Text(
                                              'Requester: $requesterName'
                                              '${requesterEmail.isNotEmpty ? ' Email: $requesterEmail' : ''}',
                                            ),

                                            const SizedBox(height: 4),
                                            Text(
                                              'Owner: $ownerName'
                                              '${ownerEmail.isNotEmpty ? ' • $ownerEmail' : ''}',
                                            ),

                                            const SizedBox(height: 6),
                                            if (created != null)
                                              Text(
                                                'Date: ${_prettyDate(created)}',
                                                style: const TextStyle(
                                                  color: Colors.black54,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
