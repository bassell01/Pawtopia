import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_routes.dart';
import '../di/injection_container.dart';
import 'route_guard.dart';
//import '../../presentations/pages/home/ui_kit_page.dart';
//import '../../presentations/pages/auth/splash_page.dart';
import '../../presentations/pages/auth/login_page.dart';
import '../../presentations/pages/auth/register_page.dart';
import '../../presentations/pages/home/home_page.dart';
import '../../presentations/pages/admin/admin_dashboard_page.dart';
import '../../presentations/pages/pets/pet_list_page.dart';
import '../../presentations/pages/pets/pet_detail_page.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final guard = const RouteGuard();

return GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(path: AppRoutes.home, builder: (_, _) => const HomePage()),
    GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
    GoRoute(path: AppRoutes.register, builder: (_, _) => const RegisterPage()),
    GoRoute(path: AppRoutes.adminDashboard, builder: (_, _) => const AdminDashboardPage()),
    //GoRoute(path: AppRoutes.uiKit, builder: (_, _) => const UiKitPage()),
    GoRoute(
        path: AppRoutes.pets,
        builder: (_, _) => const PetListPage(),
      ),
      GoRoute(
        path: AppRoutes.petDetails, 
        builder: (context, state) {
          final petId = state.pathParameters['id']!;
          return PetDetailPage(petId: petId);
        },
      ),
  ],
);

});
