import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/admin/admin_providers.dart';
import 'admin_edit_user_page.dart';

class AdminManageUsersPage extends ConsumerStatefulWidget {
  const AdminManageUsersPage({super.key});

  @override
  ConsumerState<AdminManageUsersPage> createState() => _AdminManageUsersPageState();
}

class _AdminManageUsersPageState extends ConsumerState<AdminManageUsersPage> {
  static const roles = ['all', 'user', 'shelter', 'admin'];
  String roleFilter = 'all';
  String query = '';

  @override
  Widget build(BuildContext context) {
    final remote = ref.watch(adminRemoteDataSourceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          // Create new Firestore user doc
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminEditUserPage(uid: null)),
          );
        },
      ),
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
                      hintText: 'Search by email/name/id',
                    ),
                    onChanged: (v) => setState(() => query = v.trim().toLowerCase()),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: roleFilter,
                  items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setState(() => roleFilter = v ?? 'all'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: remote.usersStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));

                var docs = snap.data?.docs ?? [];

                docs = docs.where((d) {
                  final data = d.data();
                  final id = d.id.toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  final name = (data['name'] ?? data['fullName'] ?? '').toString().toLowerCase();
                  final role = (data['role'] ?? 'user').toString();

                  final matchQuery =
                      query.isEmpty || 
                      email.contains(query) ||
                       name.contains(query) ||
                        id.contains(query);
                  final matchRole = roleFilter == 'all' || role == roleFilter;

                  return matchQuery && matchRole;
                }).toList();

                if (docs.isEmpty) return const Center(child: Text('No users found.'));

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final d = docs[i];
                    final data = d.data();
                    final uid = d.id;

                    final email = (data['email'] ?? '').toString();
                    final name = (data['name'] ?? data['fullName'] ?? 'User').toString();
                    final role = (data['role'] ?? 'user').toString();
                    final verified = data['isEmailVerified'] == true;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U')),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(email.isEmpty ? 'id: $uid' : email),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      Chip(label: Text(role)),
                                      if (verified) const Chip(label: Text('Verified')),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                  tooltip: 'Edit',
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AdminEditUserPage(uid: uid),
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
                                        title: const Text('Delete user doc?'),
                                        content: const Text('This deletes Firestore user document only.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (ok == true) {
                                      await remote.deleteUserDoc(uid);
                                    }
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
