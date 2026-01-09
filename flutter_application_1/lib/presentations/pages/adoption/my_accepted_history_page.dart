import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/widgets/adoption_request_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth/auth_state_provider.dart';
import '../../providers/adoption/adoption_streams.dart';
import '../widgets/adoption_request_card.dart';

class MyAcceptedHistoryPage extends ConsumerWidget {
  const MyAcceptedHistoryPage({super.key});

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

        final async = ref.watch(myAcceptedAdoptionRequestsStreamProvider(user.uid));

        return Scaffold(
          appBar: AppBar(title: const Text('Accepted History')),
          body: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (items) {
              if (items.isEmpty) {
                return const Center(child: Text('No accepted requests yet'));
              }

              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final r = items[i];
                  return AdoptionRequestCard(r: r); // ✅ same UI, no actions
                },
              );
            },
          ),
        );
      },
    );
  }
}
