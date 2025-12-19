import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

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
  }

  await initDependencies();

  runApp(const ProviderScope(child: App()));
}
