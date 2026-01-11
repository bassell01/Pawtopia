import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../domain/entities/adoption/adoption_request.dart';

class AdoptionRequestCard extends StatelessWidget {
  final AdoptionRequest r;

  ///Control whether to show requester row (Incoming = true, MyRequests = false)
  ///hena 3ashan lw el requester (me) mytl3lish asmy fy el MyRequests Card
  final bool showRequester;

  ///Optional fallback text when requesterName is missing
  ///display Unknown
  final String requesterFallback;


  final VoidCallback? onCancel;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onOpenChat;

  const AdoptionRequestCard({
    super.key,
    required this.r,
    this.showRequester = true,
    this.requesterFallback = 'Unknown',
    this.onCancel,
    this.onAccept,
    this.onReject,
    this.onOpenChat,
  });

  /// Title widget that guarantees showing pet name
  Widget _petTitleWidget() {
    final fromRequest = r.petName?.trim();
    if (fromRequest != null && fromRequest.isNotEmpty) {
      // Use pet name from request if available
      return Text(
        fromRequest,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      );
    }

// Fallback: listen to pets collection to resolve pet name if missing in request
    // Fallback: read from pets/{petId}
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('pets')
          .doc(r.petId)
          .snapshots(),
      builder: (context, snap) {
        String title = 'Pet';

        final data = snap.data?.data();
        if (data != null) {
          final name = (data['name'] ?? data['petName'] ?? '').toString().trim();
          if (name.isNotEmpty) title = name;
        }

        return Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final petMeta = [
      if (r.petType?.trim().isNotEmpty == true) r.petType!.trim(),
      if (r.petLocation?.trim().isNotEmpty == true) r.petLocation!.trim(),
    ].join(' • ');

    final requesterName = r.requesterName?.trim().isNotEmpty == true
        ? r.requesterName!.trim()
        : null;

    final msg = r.message?.trim();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 0.6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PetThumb(url: r.petPhotoUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -------- Title + Status
                  Row(
                    children: [
                      Expanded(child: _petTitleWidget()),
                      _StatusChip(status: r.status),
                    ],
                  ),

                  if (petMeta.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      petMeta,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],

                  // -------- Requester (only if showRequester = true)
                  if (showRequester) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Requester: ${requesterName ?? requesterFallback}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // -------- Message
                  if (msg != null && msg.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        '“$msg”',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],

                  // -------- Actions (ADD open chat support)
                  if (onCancel != null ||
                      onAccept != null ||
                      onReject != null ||
                      onOpenChat != null) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (onOpenChat != null)
                          OutlinedButton.icon(
                            onPressed: onOpenChat,
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Open Chat'),
                          ),
                        if (onCancel != null)
                          OutlinedButton.icon(
                            onPressed: onCancel,
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Cancel'),
                          ),
                        if (onReject != null)
                          OutlinedButton.icon(
                            onPressed: onReject,
                            icon: const Icon(Icons.close),
                            label: const Text('Reject'),
                          ),
                        if (onAccept != null)
                          ElevatedButton.icon(
                            onPressed: onAccept,
                            icon: const Icon(Icons.check),
                            label: const Text('Accept'),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================== Helpers =====================

class _PetThumb extends StatelessWidget {
  final String? url;
  const _PetThumb({this.url});

  @override
  Widget build(BuildContext context) {
    final hasUrl = url?.trim().isNotEmpty == true;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 78,
        height: 78,
        color: Colors.grey.shade200,
        child: hasUrl
            ? Image.network(url!, fit: BoxFit.cover)
            : const Icon(Icons.pets, size: 34),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final AdoptionStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        status.name,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
