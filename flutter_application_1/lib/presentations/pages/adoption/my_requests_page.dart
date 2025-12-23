import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/adoption/adoption_streams.dart';
import '../../providers/auth/auth_state_provider.dart';
import '../../../domain/entities/adoption/adoption_request.dart';

class MyRequestsPage extends ConsumerWidget {
  const MyRequestsPage({super.key});

  String _statusText(AdoptionStatus s) => s.name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authUserProvider);

    return authAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Auth error: $e')),
      ),
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Please login')));
        }

        final async = ref.watch(myAdoptionRequestsStreamProvider(user.uid));

        return Scaffold(
          appBar: AppBar(title: const Text('My Adoption Requests')),
          body: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (items) {
              if (items.isEmpty) {
                return const Center(child: Text('No requests yet'));
              }

              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final r = items[i];

                  return ListTile(
                    title: Text('Pet: ${r.petId}'),
                    subtitle: Text(
                      'Status: ${_statusText(r.status)}'
                      '${r.createdAt != null ? '\nCreated: ${r.createdAt}' : ''}',
                    ),
                    isThreeLine: r.createdAt != null,
                    trailing: Text(
                      (r.message ?? '').isEmpty ? '-' : r.message!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
