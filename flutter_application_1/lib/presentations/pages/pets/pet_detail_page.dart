// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';

import '../../providers/pets/pet_providers.dart';
import '../../providers/profile/profile_providers.dart';
import '../../providers/chat/chat_providers.dart';
import '../../providers/chat/chat_messages_controller.dart';

import 'pet_form_page.dart';
import '../adoption/adoption_form_page.dart'; // ✅ ADD back

class PetDetailPage extends ConsumerWidget {
  const PetDetailPage({super.key, required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petAsync = ref.watch(petDetailControllerProvider(petId));
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    Future<void> openChat({
      required String myUid,
      required String ownerUid,
    }) async {
      final threadId = await ref
          .read(createThreadIfNeededProvider)
          .call([myUid, ownerUid], petId: petId);

      if (!context.mounted) return;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => FractionallySizedBox(
          heightFactor: 0.92,
          child: _ChatThreadSheet(
            threadId: threadId,
            myUid: myUid,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Details'),
        actions: [
          petAsync.maybeWhen(
            data: (pet) {
              final isOwner = currentUid != null && pet.ownerId == currentUid;
              if (!isOwner) return const SizedBox.shrink();

              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PetFormPage(existing: pet),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete pet'),
                          content: Text('Delete "${pet.name}" permanently?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );

                      if (ok == true) {
                        await ref.read(deletePetUseCaseProvider).call(pet.id);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      }
                    },
                  ),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),

      /// =============================
      /// BODY
      /// =============================
      body: petAsync.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (pet) {
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _FullHeightPhotoSlider(photoUrls: pet.photoUrls),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${pet.type}${pet.breed != null ? " • ${pet.breed}" : ""}',
                    ),
                    if (pet.location != null) ...[
                      const SizedBox(height: 6),
                      Text('Location: ${pet.location}'),
                    ],
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(pet.description ?? 'No description'),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ],
          );
        },
      ),

      /// =============================
      /// OWNER + ACTIONS BAR (BOTTOM)
      /// =============================
      bottomNavigationBar: petAsync.maybeWhen(
        data: (pet) {
          // If not logged in -> no bottom actions
          if (currentUid == null) return const SizedBox.shrink();

          final isOwner = pet.ownerId == currentUid;
          // ✅ You wanted the owner bar fixed, but ONLY for non-owners
          if (isOwner) return const SizedBox.shrink();

          final ownerProfileAsync = ref.watch(profileStreamProvider(pet.ownerId));

          return ownerProfileAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (owner) {
              final ownerName = owner.displayName ?? owner.fullName ?? 'Owner';

              final canAdopt = pet.isAdopted != true; // same logic: hide if adopted

              return SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 8,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Owner avatar
                      CircleAvatar(
                        radius: 22,
                        backgroundImage:
                            owner.photoUrl != null && owner.photoUrl!.isNotEmpty
                                ? NetworkImage(owner.photoUrl!)
                                : null,
                        child: (owner.photoUrl == null || owner.photoUrl!.isEmpty)
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 12),

                      // Owner name
                      Expanded(
                        child: Text(
                          ownerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),

                      // Chat icon
                      IconButton(
                        tooltip: 'Chat',
                        icon: const Icon(Icons.chat_bubble_outline),
                        onPressed: () => openChat(
                          myUid: currentUid,
                          ownerUid: pet.ownerId,
                        ),
                      ),

                      // ✅ Adopt button (same logic: not owner, not adopted)
                      if (canAdopt) ...[
                        const SizedBox(width: 6),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final ok = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => AdoptionFormPage(
                                  petId: pet.id,
                                  ownerId: pet.ownerId,
                                  petName: pet.name,
                                  petType: pet.type,
                                ),
                              ),
                            );

                            if (!context.mounted) return;
                            if (ok == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Request sent ✅')),
                              );
                            }
                          },
                          icon: const Icon(Icons.volunteer_activism, size: 18),
                          label: const Text('Adopt'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }
}

/// =============================
/// FULL-HEIGHT PHOTO SLIDER
/// =============================
class _FullHeightPhotoSlider extends StatefulWidget {
  const _FullHeightPhotoSlider({required this.photoUrls});
  final List<String> photoUrls;

  @override
  State<_FullHeightPhotoSlider> createState() => _FullHeightPhotoSliderState();
}

class _FullHeightPhotoSliderState extends State<_FullHeightPhotoSlider> {
  int _index = 0;

  bool _isHttpUrl(String url) {
    final t = url.trim().toLowerCase();
    return t.startsWith('http://') || t.startsWith('https://');
  }

  bool _isLocalFilePath(String url) {
    final t = url.trim().toLowerCase();
    return t.startsWith('/') || t.startsWith('file://') || t.contains(':/');
  }

  Widget _placeholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: const Icon(Icons.pets, size: 48),
    );
  }

  Widget _smartImage(BuildContext context, String raw) {
    final url = raw.trim();
    if (url.isEmpty) return _placeholder(context);

    Widget img;

    if (_isHttpUrl(url)) {
      img = Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => _placeholder(context),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes == null
                  ? null
                  : progress.cumulativeBytesLoaded / progress.expectedTotalBytes!,
            ),
          );
        },
      );
    } else if (_isLocalFilePath(url)) {
      final file = url.toLowerCase().startsWith('file://')
          ? File.fromUri(Uri.parse(url))
          : File(url);

      img = Image.file(
        file,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => _placeholder(context),
      );
    } else {
      // gs:// or anything else not supported directly
      return _placeholder(context);
    }

    return ClipRect(
      child: InteractiveViewer(
        panEnabled: false,
        scaleEnabled: true,
        minScale: 1.0,
        maxScale: 4.0,
        boundaryMargin: const EdgeInsets.all(80),
        child: SizedBox.expand(child: img),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photoUrls.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final height = MediaQuery.of(context).size.height * 0.6;

    if (photos.isEmpty) {
      return SizedBox(height: height, child: _placeholder(context));
    }

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: photos.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => _smartImage(context, photos[i]),
          ),
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                photos.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: i == _index ? 20 : 8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// =============================
/// CHAT SHEET
/// =============================
class _ChatThreadSheet extends ConsumerStatefulWidget {
  const _ChatThreadSheet({
    required this.threadId,
    required this.myUid,
  });

  final String threadId;
  final String myUid;

  @override
  ConsumerState<_ChatThreadSheet> createState() => _ChatThreadSheetState();
}

class _ChatThreadSheetState extends ConsumerState<_ChatThreadSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesControllerProvider(widget.threadId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
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
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
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
                    controller: _ctrl,
                    decoration: const InputDecoration(hintText: 'Type message'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    final text = _ctrl.text.trim();
                    if (text.isEmpty) return;
                    _ctrl.clear();

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
