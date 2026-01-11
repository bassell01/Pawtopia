import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/utils/responsive.dart';
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
  Widget _petTitleWidget(BuildContext context) {
    final fromRequest = r.petName?.trim();
    final titleStyle = TextStyle(
      fontSize: R.s(context, 16),
      fontWeight: FontWeight.w800,
    );

    if (fromRequest != null && fromRequest.isNotEmpty) {
      return Text(
        fromRequest,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: titleStyle,
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('pets').doc(r.petId).snapshots(),
      builder: (context, snap) {
        String title = 'Pet';

        final data = snap.data?.data();
        if (data != null) {
          final name = (data['name'] ?? data['petName'] ?? '').toString().trim();
          if (name.isNotEmpty) title = name;
        }

        return Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: titleStyle,
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

    final mH = R.s(context, 12);
    final mV = R.s(context, 8);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: mH, vertical: mV),
      elevation: 0.6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(R.s(context, 16)),
      ),
      child: Padding(
        padding: EdgeInsets.all(R.s(context, 12)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PetThumb(url: r.petPhotoUrl),
            SizedBox(width: R.s(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -------- Title + Status
                  Row(
                    children: [
                      Expanded(child: _petTitleWidget(context)),
                      SizedBox(width: R.s(context, 8)),
                      FittedBox(
                        child: _StatusChip(status: r.status),
                      ),
                    ],
                  ),

                  if (petMeta.isNotEmpty) ...[
                    SizedBox(height: R.s(context, 6)),
                    Text(
                      petMeta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],

                  // -------- Requester (only if showRequester = true)
                  if (showRequester) ...[
                    SizedBox(height: R.s(context, 10)),
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: R.s(context, 18)),
                        SizedBox(width: R.s(context, 6)),
                        Expanded(
                          child: Text(
                            'Requester: ${requesterName ?? requesterFallback}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: R.s(context, 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // -------- Message
                  if (msg != null && msg.isNotEmpty) ...[
                    SizedBox(height: R.s(context, 10)),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(R.s(context, 10)),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(R.s(context, 12)),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        '“$msg”',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: R.s(context, 14),
                        ),
                      ),
                    ),
                  ],

                  // -------- Actions
                  if (onCancel != null || onAccept != null || onReject != null || onOpenChat != null) ...[
                    SizedBox(height: R.s(context, 12)),
                    Wrap(
                      spacing: R.s(context, 8),
                      runSpacing: R.s(context, 8),
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
    final size = R.s(context, 78);

    return ClipRRect(
      borderRadius: BorderRadius.circular(R.s(context, 16)),
      child: Container(
        width: size,
        height: size,
        color: Colors.grey.shade200,
        child: hasUrl
            ? Image.network(url!, fit: BoxFit.cover)
            : Icon(Icons.pets, size: R.s(context, 34)),
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
      padding: EdgeInsets.symmetric(
        horizontal: R.s(context, 10),
        vertical: R.s(context, 6),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        status.name,
        style: TextStyle(
          fontSize: R.s(context, 12),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
