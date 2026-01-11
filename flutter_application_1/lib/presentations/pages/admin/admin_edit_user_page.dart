import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin/admin_providers.dart';

class AdminEditUserPage extends ConsumerStatefulWidget {
  final String? uid; // null => create Firestore user doc
  const AdminEditUserPage({super.key, required this.uid});

  @override
  ConsumerState<AdminEditUserPage> createState() => _AdminEditUserPageState();
}

class _AdminEditUserPageState extends ConsumerState<AdminEditUserPage> {
  static const roles = ['user', 'shelter', 'admin'];

  final emailCtrl = TextEditingController();
  final nameCtrl = TextEditingController();

  String role = 'user';
  bool isEmailVerified = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.uid == null) {
      setState(() => loading = false);
      return;
    }

    final remote = ref.read(adminRemoteDataSourceProvider);
    final doc = await remote.getUserDoc(widget.uid!);
    final data = doc.data() ?? {};

    emailCtrl.text = (data['email'] ?? '').toString();
    nameCtrl.text = (data['name'] ?? data['fullName'] ?? '').toString();

    final savedRole = (data['role'] ?? 'user').toString();
    role = roles.contains(savedRole) ? savedRole : 'user';

    isEmailVerified = data['isEmailVerified'] == true;

    setState(() => loading = false);
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remote = ref.read(adminRemoteDataSourceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.uid == null ? 'Add User (Firestore)' : 'Edit User'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),

                // ✅ Role dropdown (no manual typing)
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Role'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: role,
                      isExpanded: true,
                      items: roles
                          .map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(r),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => role = v);
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Email Verified'),
                  value: isEmailVerified,
                  onChanged: (v) => setState(() => isEmailVerified = v),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () async {
                    final data = {
                      'name': nameCtrl.text.trim(),
                      'email': emailCtrl.text.trim(),
                      'role': role,
                      'isEmailVerified': isEmailVerified,
                    };

                    if (widget.uid == null) {
                      await remote.createUserDoc(data);
                    } else {
                      await remote.updateUserInfo(uid: widget.uid!, data: data);
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(widget.uid == null ? 'User created' : 'User updated'),
                        ),
                      );
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
