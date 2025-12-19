import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_routes.dart';
import '../di/injection_container.dart';
import 'route_guard.dart';
import '../../presentations/pages/home/ui_kit_page.dart';

import '../../presentations/pages/auth/splash_page.dart';
import '../../presentations/pages/auth/login_page.dart';
import '../../presentations/pages/auth/register_page.dart';
import '../../presentations/pages/home/home_page.dart';
import '../../presentations/pages/admin/admin_dashboard_page.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final guard = RouteGuard(sl());

return GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(path: AppRoutes.home, builder: (_, __) => const HomePage()),
    GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginPage()),
    GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterPage()),
    GoRoute(path: AppRoutes.adminDashboard, builder: (_, __) => const AdminDashboardPage()),
    GoRoute(path: AppRoutes.uiKit, builder: (_, __) => const UiKitPage()),
  ],
);

});
