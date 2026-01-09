import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_routes.dart';
import '../routing/route_guard.dart'; // ✅ عدّل المسار حسب مكان RouteGuard عندك

import '../../presentations/pages/auth/auth_gate.dart';
import '../../presentations/pages/auth/login_page.dart';
import '../../presentations/pages/auth/register_page.dart';
import '../../presentations/pages/home/home_page.dart';
import '../../presentations/pages/admin/admin_dashboard_page.dart';
import '../../presentations/pages/pets/pet_list_page.dart';
import '../../presentations/pages/pets/pet_detail_page.dart';
import '../../presentations/pages/pets/pet_form_page.dart';

import '../../presentations/providers/auth/auth_state_provider.dart';
import '../../presentations/providers/auth/user_role_provider.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final guard = const RouteGuard();

  final authAsync = ref.watch(authStateProvider);
  final authLoading = authAsync.isLoading;
  final firebaseUser = authAsync.valueOrNull;
  final isLoggedIn = firebaseUser != null;

  final roleAsync =
      isLoggedIn ? ref.watch(userRoleProvider) : const AsyncValue.data(null);
  final roleLoading = isLoggedIn ? roleAsync.isLoading : false;

  final role = roleAsync.valueOrNull as String?;

  return GoRouter(
    initialLocation: AppRoutes.authGate,

    redirect: (context, state) {
      return guard.redirect(
        location: state.matchedLocation,
        isLoggedIn: isLoggedIn,
        role: role,
        authLoading: authLoading,
        roleLoading: roleLoading,
      );
    },

    routes: [
      GoRoute(
        path: AppRoutes.authGate,
        builder: (_, __) => const AuthGate(),
      ),

      /// Auth
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterPage(),
      ),

      /// Pets
      GoRoute(
        path: AppRoutes.pets,
        builder: (_, __) => const PetListPage(),
      ),

      /// ✅ FIXED addPet route (no duplicates)
      GoRoute(
        path: AppRoutes.addPet,
        builder: (_, __) => const PetFormPage(),
      ),

      GoRoute(
        path: AppRoutes.petDetails,
        builder: (context, state) {
          final petId = state.pathParameters['id']!;
          return PetDetailPage(petId: petId);
        },
      ),

      /// Main
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const HomePage(),
      ),

      /// Admin
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (_, __) => const AdminDashboardPage(),
      ),
    ],
  );
});
