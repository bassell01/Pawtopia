import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/widgets/adoption_request_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/adoption/adoption_streams.dart';
import '../../providers/adoption/adoption_controller.dart';
import '../../providers/auth/auth_state_provider.dart';
import '../../../domain/entities/adoption/adoption_request.dart';

class IncomingRequestsPage extends ConsumerWidget {
  const IncomingRequestsPage({super.key});

  Future<bool> _confirmAccept(BuildContext context, String petName) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Accept request?'),
        content: Text(
          'Accepting will mark this pet as adopted and reject other pending requests.\n\n'
          'Pet: "$petName"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  Future<bool> _confirmReject(BuildContext context, String petName) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject request?'),
        content: Text('Reject request for "$petName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    return res ?? false;
  }

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
        final controller = ref.read(adoptionControllerProvider.notifier);

        return Scaffold(
          appBar: AppBar(title: const Text('Incoming Requests')),
          body: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (items) {
              if (items.isEmpty) {
                return const Center(child: Text('No incoming requests'));
              }

              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final r = items[i];
                  final canDecide = r.status == AdoptionStatus.pending;

                  final petTitle = r.petName ?? 'Pet: ${r.petId}';

                  return AdoptionRequestCard(
                    r: r,
                    onAccept: (!canDecide || ctrlState.isLoading)
                        ? null
                        : () async {
                            final okConfirm = await _confirmAccept(context, petTitle);
                            if (!okConfirm) return;

                            final ok = await controller.updateStatus(
                              requestId: r.id,
                              status: AdoptionStatus.accepted,
                              threadId: r.threadId,
                            );

                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok
                                      ? 'Request accepted ✅'
                                      : (ref.read(adoptionControllerProvider).error ??
                                          'Failed to accept'),
                                ),
                              ),
                            );
                          },
                    onReject: (!canDecide || ctrlState.isLoading)
                        ? null
                        : () async {
                            final okConfirm = await _confirmReject(context, petTitle);
                            if (!okConfirm) return;

                            final ok = await controller.updateStatus(
                              requestId: r.id,
                              status: AdoptionStatus.rejected,
                              threadId: r.threadId,
                            );

                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok
                                      ? 'Request rejected ✅'
                                      : (ref.read(adoptionControllerProvider).error ??
                                          'Failed to reject'),
                                ),
                              ),
                            );
                          },
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
