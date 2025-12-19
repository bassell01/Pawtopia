import 'package:flutter/material.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/empty_state.dart';

class UiKitPage extends StatefulWidget {
  const UiKitPage({super.key});

  @override
  State<UiKitPage> createState() => _UiKitPageState();
}

class _UiKitPageState extends State<UiKitPage> {
  final emailController = TextEditingController();
  final passController = TextEditingController();

  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('UI Kit (Day 5 Test)'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Typography', style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('This is body text', style: textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text('This is caption text', style: textTheme.bodySmall),
          const Divider(height: 32),

          Text('Text Fields', style: textTheme.titleLarge),
          const SizedBox(height: 12),
          AppTextField(
            controller: emailController,
            label: 'Email',
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: passController,
            label: 'Password',
            obscure: true,
          ),
          const Divider(height: 32),

          Text('Buttons', style: textTheme.titleLarge),
          const SizedBox(height: 12),
          AppButton(
            text: 'Primary Button',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('AppButton works ✅')),
              );
            },
          ),
          const SizedBox(height: 12),
          AppButton(
            text: 'Loading Button',
            loading: true,
            onPressed: () {},
          ),
          const SizedBox(height: 12),
          AppButton(
            text: 'Disabled Button',
            onPressed: null,
          ),
          const SizedBox(height: 12),
          AppButton(
            text: loading ? 'Stop Local Loading' : 'Start Local Loading',
            onPressed: () => setState(() => loading = !loading),
          ),
          const Divider(height: 32),

          Text('State Widgets', style: textTheme.titleLarge),
          const SizedBox(height: 12),
          const SizedBox(
            height: 80,
            child: LoadingIndicator(),
          ),
          const SizedBox(height: 12),
          const ErrorView(message: 'Sample error message ❌'),
          const SizedBox(height: 12),
          const EmptyState(text: 'Nothing here yet 👀'),
          const SizedBox(height: 24),

          Text(
            'If everything looks consistent and no UI is duplicated, Day 5 is done ✅',
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
