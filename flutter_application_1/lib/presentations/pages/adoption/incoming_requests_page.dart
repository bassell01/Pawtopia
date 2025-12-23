import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/adoption/adoption_streams.dart';
import '../../providers/adoption/adoption_controller.dart';
import '../../providers/auth/auth_state_provider.dart';
import '../../../domain/entities/adoption/adoption_request.dart';

class IncomingRequestsPage extends ConsumerWidget {
  const IncomingRequestsPage({super.key});

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

        final async = ref.watch(incomingAdoptionRequestsStreamProvider(user.uid));
        final ctrlState = ref.watch(adoptionControllerProvider);

        return Scaffold(
          appBar: AppBar(title: const Text('Incoming Requests')),
          body: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (items) {
              if (items.isEmpty) return const Center(child: Text('No incoming requests'));

              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final r = items[i];
                  final canDecide = r.status == AdoptionStatus.pending;

                  return ListTile(
                    title: Text('Pet: ${r.petId}'),
                    subtitle: Text(
                      'From: ${r.requesterId}\n'
                      'Status: ${r.status.name}\n'
                      '${r.message ?? ''}',
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Accept',
                          onPressed: (!canDecide || ctrlState.isLoading)
                              ? null
                              : () async {
                                  final ok = await ref
                                      .read(adoptionControllerProvider.notifier)
                                      .updateStatus(
                                        requestId: r.id,
                                        status: AdoptionStatus.accepted,
                                      );

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(ok
                                            ? 'Request accepted ✅'
                                            : (ref.read(adoptionControllerProvider).error ??
                                                'Failed to accept')),
                                      ),
                                    );
                                  }
                                },
                          icon: const Icon(Icons.check, color: Colors.green),
                        ),
                        IconButton(
                          tooltip: 'Reject',
                          onPressed: (!canDecide || ctrlState.isLoading)
                              ? null
                              : () async {
                                  final ok = await ref
                                      .read(adoptionControllerProvider.notifier)
                                      .updateStatus(
                                        requestId: r.id,
                                        status: AdoptionStatus.rejected,
                                      );

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(ok
                                            ? 'Request rejected ✅'
                                            : (ref.read(adoptionControllerProvider).error ??
                                                'Failed to reject')),
                                      ),
                                    );
                                  }
                                },
                          icon: const Icon(Icons.close, color: Colors.red),
                        ),
                      ],
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
