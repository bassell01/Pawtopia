import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Profile tab'));
  }
}

/* -------------------- CHAT TAB -------------------- */

class _ChatTab extends ConsumerWidget {
  const _ChatTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Please login to use chat'));
    }

    final threadsAsync =
        ref.watch(chatThreadsControllerProvider(user.uid));

    return threadsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Chat error:\n$e')),
      data: (threads) {
        if (threads.isEmpty) {
          return const Center(
            child: Text(
              'No chats yet.\n\nLogin with another account and send a message.',
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.separated(
          itemCount: threads.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final t = threads[i];
            return ListTile(
              leading: const Icon(Icons.forum),
              title: Text(t.petId ?? 'General chat'),
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
            );
          },
        );
      },
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
