import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/adoption/adoption_controller.dart';
import '../../providers/auth/auth_state_provider.dart';

class AdoptionFormPage extends ConsumerStatefulWidget {
  const AdoptionFormPage({
    super.key,
    required this.petId,
    required this.ownerId,
  });
  

  final String petId;
  final String ownerId;

  @override
  ConsumerState<AdoptionFormPage> createState() => _AdoptionFormPageState();
}

class _AdoptionFormPageState extends ConsumerState<AdoptionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _msgController = TextEditingController();

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // ✅ safer: handle loading/null explicitly
    final authState = ref.read(authUserProvider);
    final me = authState.value;

    if (authState.isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading user...')),
      );
      return;
    }

    if (me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first.')),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final controller = ref.read(adoptionControllerProvider.notifier);

    final id = await controller.createRequest(
      petId: widget.petId,
      ownerId: widget.ownerId, // ✅ must match pets.ownerId
      requesterId: me.uid,
      message: _msgController.text.trim().isEmpty ? null : _msgController.text.trim(),
    );

    if (!mounted) return;

    if (id != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adoption request sent ✅')),
      );
      Navigator.of(context).pop();
    } else {
      // ✅ don’t assume state has .error if you used AsyncValue
      final state = ref.read(adoptionControllerProvider);
      final err = state.error ?? 'Failed to send request';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adoptionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Adoption Request')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _msgController,
                decoration: const InputDecoration(
                  labelText: 'Message (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (v) {
                  if (v != null && v.length > 500) return 'Max 500 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state.isLoading ? null : _submit,
                  child: state.isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
