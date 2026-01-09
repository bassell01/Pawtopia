import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';

import 'presentations/providers/auth/auth_state_provider.dart';
import 'presentations/providers/auth/auth_providers.dart';
import 'presentations/providers/notifications/notification_providers.dart';

// ✅ NEW import for theme mode provider
import 'presentations/providers/theme/theme_mode_provider.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  StreamSubscription? _tapSub;
  String? _lastSavedTokenForUid;

  @override
  void initState() {
    super.initState();

    // Listen for notification taps -> navigate via GoRouter
    _tapSub = NotificationService.instance.onTap.listen((event) {
      final deepLink = event.deepLink;
      if (deepLink != null && deepLink.isNotEmpty) {
        // Use router from provider
        final router = ref.read(goRouterProvider);
        router.go(deepLink);
      }
    });
  }

  @override
  void dispose() {
    _tapSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Theme mode (System / Light / Dark)
    final themeMode = ref.watch(themeModeProvider);

    ref.listen(authUserProvider, (prev, next) {
      next.whenData((firebaseUser) {
        // FirebaseAuth is already logged in (even after hot restart)
        // so re-load domain user into AuthController
        ref.read(authControllerProvider.notifier).checkAuthState();
      });
    });

    final router = ref.watch(goRouterProvider);

    // When user logs in/out, save token once
    ref.listen(authUserProvider, (prev, next) async {
      final firebaseUser = next.asData?.value;

      if (firebaseUser == null) {
        _lastSavedTokenForUid = null;
        return;
      }

      final uid = firebaseUser.uid;
      if (_lastSavedTokenForUid == uid) return;

      final token = await NotificationService.instance.getToken();
      if (token == null || token.isEmpty) return;

      await ref.read(saveDeviceTokenUseCaseProvider).call(uid: uid, token: token);
      _lastSavedTokenForUid = uid;
    });

    // Re-sync domain auth after hot restart / app reopen
    ref.listen(authUserProvider, (prev, next) {
      next.whenData((firebaseUser) {
        ref.read(authControllerProvider.notifier).checkAuthState();
      });
    });

    // Save token using FirebaseAuth user (most reliable)
    ref.listen(authUserProvider, (prev, next) async {
      final firebaseUser = next.asData?.value;

      if (firebaseUser == null) {
        _lastSavedTokenForUid = null;
        return;
      }

      final uid = firebaseUser.uid;
      if (_lastSavedTokenForUid == uid) return;

      final token = await NotificationService.instance.getToken();
      if (token == null || token.isEmpty) return;

      await ref.read(saveDeviceTokenUseCaseProvider).call(uid: uid, token: token);
      _lastSavedTokenForUid = uid;
    });

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Pet Adoption & Rescue',
      themeMode: themeMode,
      theme: AppTheme.light,
      // ✅ NEW: dark theme
      darkTheme: AppTheme.dark,
      // ✅ NEW: controls which theme is active
      routerConfig: router,
    );
  }
}
