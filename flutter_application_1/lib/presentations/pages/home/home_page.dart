import 'package:flutter/material.dart';
import 'package:flutter_application_1/presentations/pages/adoption/adoption_hub_page.dart';
import 'package:flutter_application_1/presentations/pages/notifications/notifications_center_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';

import '../chat/chat_list_page.dart';
import '../favorites/favorites_page.dart';
import '../pets/pet_list_page.dart';

import '../profile/profile_page.dart';

import '../../providers/profile/profile_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      const _PetsTab(),
      const FavoritesPage(),
      const _AdoptionTab(),
      const ChatListPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pawtopia'),
        actions: [
          // AI icon in AppBar
          IconButton(
            tooltip: 'AI Matching',
            onPressed: () => context.push(AppRoutes.aiMatching),
            icon: const Icon(Icons.auto_awesome),
          ),

          // Notifications in AppBar
          Consumer(
            builder: (context, ref, _) {
              final unread = ref.watch(unreadNotificationsCountProvider);

              return IconButton(
                tooltip: 'Notifications',
                onPressed: () => context.push(AppRoutes.notifications),
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications),
                    if (unread > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.pets), label: 'Pets'),
          NavigationDestination(icon: Icon(Icons.favorite), label: 'Favorites'),
          NavigationDestination(
            icon: Icon(Icons.assignment),
            label: 'Adoption',
          ),
          NavigationDestination(icon: Icon(Icons.chat), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

/* -------------------- TABS -------------------- */

class _PetsTab extends StatelessWidget {
  const _PetsTab();

  @override
  Widget build(BuildContext context) {
    return const PetListPage();
  }
}

class _AdoptionTab extends StatelessWidget {
  const _AdoptionTab();

  @override
  Widget build(BuildContext context) {
    return const AdoptionHubPage();
  }
}
