import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/widgets/admin/stats_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../providers/admin/admin_controller.dart';
import 'admin_manage_users_page.dart';
import 'admin_manage_pets_page.dart';
import 'admin_manage_adoption_requests_page.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(adminControllerProvider.notifier).loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(adminControllerProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () =>
                  ref.read(adminControllerProvider.notifier).refresh(),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );

                if (ok == true) {
                  await FirebaseAuth.instance.signOut();

                  if (context.mounted) {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                }
              },
            ),
          ],

          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pets'),
              Tab(text: 'Requests'),
              Tab(text: 'Profiles'),
            ],
          ),
        ),
        body: Builder(
          builder: (_) {
            if (st.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (st.failure != null) {
              return Center(child: Text('Error: ${st.failure}'));
            }

            final s = st.stats;
            if (s == null) {
              return const Center(child: Text('No data yet.'));
            }

            return TabBarView(
              children: [
                // ---------------- Pets Tab ----------------
                ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    StatsCard(
                      title: 'Total Pets',
                      value: s.totalPets,
                      icon: Icons.pets,
                    ),
                    StatsCard(
                      title: 'Available',
                      value: s.availablePets,
                      icon: Icons.check_circle_outline,
                    ),
                    StatsCard(
                      title: 'Adopted',
                      value: s.adoptedPets,
                      icon: Icons.favorite,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminManagePetsPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.manage_search),
                      label: const Text('Manage Pets'),
                    ),
                  ],
                ),

                // ---------------- Requests Tab ----------------
                ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    StatsCard(
                      title: 'Pending',
                      value: s.pendingRequests,
                      icon: Icons.hourglass_bottom,
                    ),
                    StatsCard(
                      title: 'Approved',
                      value: s.approvedRequests,
                      icon: Icons.verified,
                    ),
                    StatsCard(
                      title: 'Rejected',
                      value: s.rejectedRequests,
                      icon: Icons.cancel,
                    ),
                    StatsCard(
                      title: 'Completed',
                      value: s.completedRequests,
                      icon: Icons.done_all,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AdminManageAdoptionRequestsPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.list_alt),
                      label: const Text('Manage Adoption Requests'),
                    ),
                  ],
                ),

                // ---------------- Profiles Tab ----------------
                ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    // ✅ "Users" بدل "Adopters" لأن role عندك = user
                    StatsCard(
                      title: 'Users',
                      value: s.totalAdopters,
                      icon: Icons.person,
                    ),
                    StatsCard(
                      title: 'Shelters',
                      value: s.totalShelters,
                      icon: Icons.home_work,
                    ),
                    StatsCard(
                      title: 'Admins',
                      value: s.totalAdmins,
                      icon: Icons.admin_panel_settings,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminManageUsersPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.supervised_user_circle),
                      label: const Text('Manage Users'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
