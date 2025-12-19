import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_routes.dart';
import '../../providers/profile/profile_providers.dart';
import '../../providers/chat/profile_search_providers.dart';
import '../../providers/auth/auth_providers.dart';

import '../../providers/chat/chat_threads_controller.dart';
import '../../providers/chat/chat_messages_controller.dart';
import '../../providers/chat/chat_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      const _PetsTab(),
      const _AdoptionTab(),
      const _ChatTab(), 
      const _ProfileTab(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Pawtopia')),
      body: IndexedStack(
        index: _index,
        children: tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.pets), label: 'Pets'),
          NavigationDestination(icon: Icon(Icons.assignment), label: 'Adoption'),
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
    return const Center(child: Text('Pets tab'));
  }
}

class _AdoptionTab extends StatelessWidget {
  const _AdoptionTab();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Adoption tab'));
  }
}

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      return const Center(child: Text('Not logged in'));
    }

    final profileAsync = ref.watch(profileStreamProvider(firebaseUser.uid));

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Profile error:\n$e')),
      data: (profile) {
        final name = profile.displayName ?? profile.fullName;
        final email = profile.email;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage:
                    (profile.photoUrl != null && profile.photoUrl!.isNotEmpty)
                        ? NetworkImage(profile.photoUrl!)
                        : null,
                child: (profile.photoUrl == null || profile.photoUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
              const SizedBox(height: 16),

              Text(
                name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),

              Text(
                email,
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 20),

              if ((profile.phoneNumber ?? '').isNotEmpty)
                Text('Phone: ${profile.phoneNumber}'),

              if ((profile.city ?? '').isNotEmpty)
                Text('City: ${profile.city}'),

              if ((profile.bio ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Bio: ${profile.bio}'),
              ],

              const SizedBox(height: 32),

              ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              ),
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).signOut();

                if (!context.mounted) return;

                context.go(AppRoutes.login);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              ),

            ],
          ),
        );
      },
    );
  }
}



/* -------------------- CHAT TAB -------------------- */

class _ChatTab extends ConsumerWidget {
  const _ChatTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('You need to login to use chat.'),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => context.go(AppRoutes.login),
          icon: const Icon(Icons.login),
          label: const Text('Login'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => context.go(AppRoutes.register),
          child: const Text('Create account'),
        ),
      ],
    ),
  );
}

    final threadsAsync =
        ref.watch(chatThreadsControllerProvider(user.uid));

    return threadsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Chat error:\n$e')),
      data: (threads) {
      if (threads.isEmpty) {
        return _NewChatByNamePanel(myUid: user.uid);
      }



        return ListView.separated(
          itemCount: threads.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final t = threads[i];
            final otherUserId =
    t.participantIds.firstWhere((id) => id != user.uid);

final otherProfileAsync = ref.watch(profileStreamProvider(otherUserId));

return otherProfileAsync.when(
  loading: () => ListTile(
    leading: const CircleAvatar(child: Icon(Icons.person)),
    title: const Text('Loading...'),
    subtitle: Text(t.lastMessage ?? 'No messages yet'),
    onTap: () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _ChatThreadView(
            threadId: t.id,
            myUid: user.uid,
          ),
        ),
      );
    },
  ),
  error: (e, _) => ListTile(
    leading: const CircleAvatar(child: Icon(Icons.person)),
    title: const Text('Unknown user'),
    subtitle: Text(t.lastMessage ?? 'No messages yet'),
    onTap: () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _ChatThreadView(
            threadId: t.id,
            myUid: user.uid,
          ),
        ),
      );
    },
  ),
  data: (profile) {
    final name = profile.displayName ?? profile.fullName;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: (profile.photoUrl != null && profile.photoUrl!.isNotEmpty)
            ? NetworkImage(profile.photoUrl!)
            : null,
        child: (profile.photoUrl == null || profile.photoUrl!.isEmpty)
            ? const Icon(Icons.person)
            : null,
      ),
      title: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        t.lastMessage ?? 'No messages yet',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _ChatThreadView(
              threadId: t.id,
              myUid: user.uid,
            ),
          ),
        );
      },
    );
  },
);

          },
        );
      },
    );
  }
}

class _NewChatByNamePanel extends ConsumerStatefulWidget {
  const _NewChatByNamePanel({required this.myUid});
  final String myUid;

  @override
  ConsumerState<_NewChatByNamePanel> createState() => _NewChatByNamePanelState();
}

class _NewChatByNamePanelState extends ConsumerState<_NewChatByNamePanel> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _searchCtrl.text;
    final resultsAsync = ref.watch(profilesSearchProvider(q));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              labelText: 'Search users by name',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: q.trim().isEmpty
                ? const Center(child: Text('Type a name to search…'))
                : resultsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Search error:\n$e')),
                    data: (profiles) {
                      // Filter out myself
                      final filtered = profiles.where((p) => p['userId'] != widget.myUid).toList();

                      if (filtered.isEmpty) {
                        return const Center(child: Text('No users found.'));
                      }

                      return ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final p = filtered[i];
                          final name = (p['displayName'] as String?) ?? 'No name';
                          final email = (p['email'] as String?) ?? '';
                          final otherUid = p['userId'] as String;

                          return ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(name),
                            subtitle: Text(email),
                            onTap: () async {
                              // Create / get thread
                              final threadId = await ref
                                  .read(createThreadIfNeededProvider)
                                  .call([widget.myUid, otherUid], petId: null);

                              if (!context.mounted) return;

                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => _ChatThreadView(
                                    threadId: threadId,
                                    myUid: widget.myUid,
                                  ),
                                ),
                              );
                            },
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



class _ChatThreadView extends ConsumerStatefulWidget {
  const _ChatThreadView({
    required this.threadId,
    required this.myUid,
  });

  final String threadId;
  final String myUid;

  @override
  ConsumerState<_ChatThreadView> createState() => _ChatThreadViewState();
}

class _ChatThreadViewState extends ConsumerState<_ChatThreadView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync =
        ref.watch(chatMessagesControllerProvider(widget.threadId));

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (messages) => ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(12),
                itemCount: messages.length,
                itemBuilder: (_, i) {
                  final m = messages[i];
                  final isMe = m.senderId == widget.myUid;

                  return Align(
                    alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Colors.blue.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(m.text),
                    ),
                  );
                },
              ),
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration:
                        const InputDecoration(hintText: 'Type message'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    final text = _controller.text.trim();
                    if (text.isEmpty) return;
                    _controller.clear();

                    await ref.read(sendMessageProvider).call(
                          threadId: widget.threadId,
                          senderId: widget.myUid,
                          text: text,
                        );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
