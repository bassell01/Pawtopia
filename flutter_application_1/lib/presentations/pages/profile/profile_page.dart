import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/image_picker_service.dart';
import '../../providers/auth/auth_providers.dart';
import '../../providers/profile/profile_providers.dart';

// ✅ Theme toggle provider
import '../../providers/theme/theme_mode_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();

    // Load profile once after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(currentUserIdProvider);
      if (userId != null) {
        ref.read(profileControllerProvider.notifier).loadProfile(userId);
      }
    });
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authControllerProvider.notifier).signOut();

      if (!mounted) return;

      // Keep your existing navigation style (Named route)
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Future<void> _handleImageUpload() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final imagePath = await ImagePickerService.pickImage();
    if (imagePath != null) {
      await ref
          .read(profileControllerProvider.notifier)
          .uploadProfileImage(userId: userId, imagePath: imagePath);
    }
  }

  void _toggleEdit() {
    setState(() => _isEditing = !_isEditing);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.profile;

    // ✅ Theme mode
    final themeMode = ref.watch(themeModeProvider);

    if (profileState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (profile == null) {
      return const Scaffold(body: Center(child: Text('Profile not found')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: _toggleEdit,
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _handleSignOut),
        ],
      ),
      body: _isEditing
          ? ProfileEditView(profile: profile)
          : ProfileViewMode(
              profile: profile,
              user: user,
              onImageUpload: _handleImageUpload,
              themeMode: themeMode,
              onToggleTheme: () {
                ref
                    .read(themeModeProvider.notifier)
                    .state = (themeMode == ThemeMode.dark)
                    ? ThemeMode.light
                    : ThemeMode.dark;
              },
              onSignOut: _handleSignOut,
            ),
    );
  }
}

class ProfileViewMode extends StatelessWidget {
  final dynamic profile;
  final dynamic user;
  final VoidCallback onImageUpload;

  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onSignOut;

  const ProfileViewMode({
    super.key,
    required this.profile,
    required this.user,
    required this.onImageUpload,
    required this.themeMode,
    required this.onToggleTheme,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    // ✅ FIX: UserRole may not have `.name`
    final role = user?.role;
    final String roleText = (role == null)
        ? 'USER'
        : (() {
            final raw = role.toString(); // e.g. "UserRole.admin"
            return raw.contains('.')
                ? raw.split('.').last.toUpperCase()
                : raw.toUpperCase();
          })();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile photo
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage:
                    (profile.photoUrl != null &&
                        (profile.photoUrl as String).isNotEmpty)
                    ? NetworkImage(profile.photoUrl!)
                    : null,
                child:
                    (profile.photoUrl == null ||
                        (profile.photoUrl as String).isEmpty)
                    ? const Icon(Icons.person, size: 60)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: onImageUpload,
                  style: IconButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            profile.fullName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),

          // Role badge
          Chip(
            label: Text(roleText),
            backgroundColor: primary.withOpacity(0.2),
          ),

          const SizedBox(height: 16),

          // ✅ Theme toggle
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 20,
                ),
              ),
              onPressed: onToggleTheme,
              icon: Icon(
                themeMode == ThemeMode.dark
                    ? Icons.dark_mode
                    : Icons.light_mode,
              ),
              label: Text(
                themeMode == ThemeMode.dark
                    ? 'Dark Mode: ON'
                    : 'Dark Mode: OFF',
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Sign out
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 20,
                ),
              ),
              onPressed: onSignOut,
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
            ),
          ),

          const SizedBox(height: 24),

          // Profile details
          _buildInfoCard(context, [
            _buildInfoRow(Icons.email, 'Email', profile.email),
            if (profile.phoneNumber != null &&
                (profile.phoneNumber as String).isNotEmpty)
              _buildInfoRow(Icons.phone, 'Phone', profile.phoneNumber!),
            if (profile.bio != null && (profile.bio as String).isNotEmpty)
              _buildInfoRow(Icons.info, 'Bio', profile.bio!),
            if (profile.address != null &&
                (profile.address as String).isNotEmpty)
              _buildInfoRow(
                Icons.location_on,
                'Address',
                '${profile.address}, ${profile.city}, ${profile.state} ${profile.zipCode}',
              ),
          ]),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileEditView extends ConsumerStatefulWidget {
  final dynamic profile;

  const ProfileEditView({super.key, required this.profile});

  @override
  ConsumerState<ProfileEditView> createState() => _ProfileEditViewState();
}

class _ProfileEditViewState extends ConsumerState<ProfileEditView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipCodeController;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.profile.displayName,
    );
    _phoneController = TextEditingController(text: widget.profile.phoneNumber);
    _bioController = TextEditingController(text: widget.profile.bio);
    _addressController = TextEditingController(text: widget.profile.address);
    _cityController = TextEditingController(text: widget.profile.city);
    _stateController = TextEditingController(text: widget.profile.state);
    _zipCodeController = TextEditingController(text: widget.profile.zipCode);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final success = await ref
        .read(profileControllerProvider.notifier)
        .updateProfile(
          userId: userId,
          displayName: _displayNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          bio: _bioController.text.trim(),
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          zipCode: _zipCodeController.text.trim(),
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Bio',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stateController,
              decoration: const InputDecoration(
                labelText: 'State',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _zipCodeController,
              decoration: const InputDecoration(
                labelText: 'ZIP Code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: profileState.isUpdating ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: profileState.isUpdating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
