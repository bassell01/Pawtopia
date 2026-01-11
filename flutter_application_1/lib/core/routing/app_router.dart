import 'package:flutter/material.dart';
import 'package:flutter_application_1/presentations/pages/adoption/adoption_form_page.dart';
import 'package:flutter_application_1/presentations/pages/adoption/incoming_requests_page.dart';
import 'package:flutter_application_1/presentations/pages/adoption/my_requests_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_routes.dart';
import '../routing/route_guard.dart';
import '../../presentations/pages/missing_pets_ai/ai_matching_page.dart';
import '../../presentations/pages/chat/chat_thread_page.dart';
import '../../presentations/pages/notifications/notifications_center_page.dart';
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

// GoRouter is provided via Riverpod so it can react to auth/role changes automatically
final goRouterProvider = Provider<GoRouter>((ref) {
  // RouteGuard contains redirect rules (auth/role protection) for the entire app
  final guard = const RouteGuard();

  final authAsync = ref.watch(authStateProvider);
  final authLoading = authAsync.isLoading;
  final firebaseUser = authAsync.valueOrNull;
  final isLoggedIn = firebaseUser != null;

  final roleAsync = isLoggedIn
      ? ref.watch(userRoleProvider)
      : const AsyncValue.data(null);

  // Track role loading to avoid redirecting before role is known
  final roleLoading = isLoggedIn ? roleAsync.isLoading : false;

  final role = roleAsync.valueOrNull as String?;

  return GoRouter(
    // Start the app at AuthGate to decide initial screen based on auth state
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
      // ------------------ Auth Gate ------------------
      // A decision screen that routes user to login/home depending on auth state
      GoRoute(path: AppRoutes.authGate, builder: (_, __) => const AuthGate()),

      // ------------------ Chat shortcut ------------------
      // Opens HomePage directly on the Chat tab (initialTab: 3)

      // Chat from notifications
      GoRoute(
        path: AppRoutes.chat,
        builder: (_, __) => const HomePage(initialTab: 3),
      ),

      // ------------------ Chat Thread ------------------
      // Reads threadId from URL params and opens ChatThreadPage(threadId)
      GoRoute(
        path: AppRoutes.chatThread,
        builder: (context, state) {
          final threadId = state.pathParameters['id']!;
          return ChatThreadPage(threadId: threadId);
        },
      ),

      // ------------------ Notifications Center ------------------
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsCenterPage(),
      ),

      // ------------------ Authentication ------------------
      // Login / Register screens
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginPage()),

      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterPage(),
      ),

      // ------------------ AI Matching feature ------------------
      GoRoute(
        path: AppRoutes.aiMatching,
        builder: (_, __) => const AiMatchingPage(),
      ),

      // ------------------ Pets ------------------
      // Pet list / add pet / pet details
      GoRoute(path: AppRoutes.pets, builder: (_, __) => const PetListPage()),

      GoRoute(path: AppRoutes.addPet, builder: (_, __) => const PetFormPage()),

      GoRoute(
        path: AppRoutes.petDetails,
        builder: (context, state) {
          final petId = state.pathParameters['id']!;
          return PetDetailPage(petId: petId);
        },
      ),

      ///------------------ Main Home ------------------
      GoRoute(path: AppRoutes.home, builder: (_, __) => const HomePage()),

      // ------------------ Adoption Form ------------------
      GoRoute(
        path: AppRoutes.adoptionForm,
        builder: (context, state) {
          // Read extra data passed during navigation to this route
          final extra = state.extra;

          if (extra is Map<String, dynamic>) {
            final petId = extra['petId']?.toString();
            final ownerId = extra['ownerId']?.toString();

            if (petId != null && ownerId != null) {
              return AdoptionFormPage(
                petId: petId,
                ownerId: ownerId,
                petName: '',
                petType: '',
              );
            }
          }
          return const Scaffold(
            body: Center(child: Text('Missing petId/ownerId (route extra)')),
          );
        },
      ),

      // Opens the page that shows the current user's adoption requests
      GoRoute(
        path: AppRoutes.myRequests,
        builder: (_, __) => const MyRequestsPage(),
      ),

      // Opens the page that shows adoption requests received for the user's pets (owner/shelter side)
      GoRoute(
        path: AppRoutes.incomingRequests,
        builder: (_, __) => const IncomingRequestsPage(),
      ),

      // ------------------ Admin ------------------
      // Opens the Admin Dashboard
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (_, __) => const AdminDashboardPage(),
      ),
    ],
  );
});
