import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/notification_service.dart';

import 'app.dart';
import 'config/firebase_options.dart';
import 'core/di/injection_container.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase ONCE
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('🔥 Firebase initialized: ${Firebase.apps.first.name}');
  }

  await initDependencies();
  await NotificationService.instance.init();
  runApp(const ProviderScope(child: App()));

  
}
