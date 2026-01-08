import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_routes.dart';

// Pages
import '../../presentations/pages/notifications/notifications_center_page.dart';
import '../../presentations/pages/auth/auth_gate.dart';
import '../../presentations/pages/auth/login_page.dart';
import '../../presentations/pages/auth/register_page.dart';
import '../../presentations/pages/home/home_page.dart';
import '../../presentations/pages/admin/admin_dashboard_page.dart';
import '../../presentations/pages/pets/pet_list_page.dart';
import '../../presentations/pages/pets/pet_detail_page.dart';
import '../../presentations/pages/pets/pet_form_page.dart';
import '../../presentations/pages/adoption/adoption_form_page.dart';
import '../../presentations/pages/adoption/my_requests_page.dart';
import '../../presentations/pages/adoption/incoming_requests_page.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.authGate,
    routes: [
      // Gate
      GoRoute(
        path: AppRoutes.authGate,
        builder: (_, __) => const AuthGate(),
      ),

      // Auth
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterPage(),
      ),

      // Main
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const HomePage(),
      ),
      
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const NotificationsCenterPage(),
      ),


      // Pets
      GoRoute(
        path: AppRoutes.pets,
        builder: (_, __) => const PetListPage(),
      ),
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

      GoRoute(
        path: AppRoutes.adoptionForm,
        builder: (context, state) {
          final extra = state.extra;

          if (extra is Map<String, dynamic>) {
            final petId = extra['petId']?.toString();
            final ownerId = extra['ownerId']?.toString();

            if (petId != null && ownerId != null) {
              return AdoptionFormPage(petId: petId, ownerId: ownerId);
            }
          }

          return const Scaffold(
            body: Center(child: Text('Missing petId/ownerId (route extra)')),
          );
        },
      ),

      GoRoute(
        path: AppRoutes.myRequests,
        builder: (_, __) => const MyRequestsPage(),
      ),
      GoRoute(
        path: AppRoutes.incomingRequests,
        builder: (_, __) => const IncomingRequestsPage(),
      ),

      // Admin
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (_, __) => const AdminDashboardPage(),
      ),
    ],
  );
});
