import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentations/providers/auth/auth_providers.dart';
import '../../../presentations/providers/notifications/notification_providers.dart';
import '../../../presentations/providers/notifications/notification_controller.dart';

final notificationControllerProvider = Provider<NotificationController>((ref) {
  return NotificationController(
    getStream: ref.watch(getNotificationStreamUseCaseProvider),
    markRead: ref.watch(markNotificationReadUseCaseProvider),
  );
});

final notificationsStreamProvider = StreamProvider.autoDispose((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return const Stream.empty();

  final controller = ref.watch(notificationControllerProvider);
  return controller.streamForUser(uid);
});

class NotificationsCenterPage extends ConsumerWidget {
  const NotificationsCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserIdProvider);

    final asyncNotifs = ref.watch(notificationsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'),leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => context.pop(),
  ),),
      body: uid == null
          ? const Center(child: Text('Please login to view notifications.'))
          : asyncNotifs.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(child: Text('No notifications yet.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final n = items[i];
                    return ListTile(
                      tileColor: n.isRead ? null : Theme.of(context).colorScheme.primary.withOpacity(0.08),
                      title: Text(n.title),
                      subtitle: Text(n.body),
                      trailing: n.isRead ? null : const Icon(Icons.fiber_new),
                      onTap: () async {
                        // mark read
                        await ref.read(notificationControllerProvider).markAsRead(uid, n.id);

                        // navigate if deepLink exists
                        final deepLink = n.deepLink;
                        if (deepLink != null && deepLink.isNotEmpty) {
                          // Use GoRouter from context
                          // ignore: use_build_context_synchronously
                          Navigator.of(context).pop(); // optional: close page before navigate
                          // ignore: use_build_context_synchronously
                          // GoRouter is available via MaterialApp.router; context has it
                          // ignore: use_build_context_synchronously
                          // Using `go` requires go_router import; easiest is context.go if you want.
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
    );
  }
}
