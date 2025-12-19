import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_routes.dart';

class RouteGuard {
  RouteGuard(this._auth);
  final FirebaseAuth _auth;

  String? requireAuth(GoRouterState state) {
    final user = _auth.currentUser;
    final isAuthPage = state.matchedLocation == AppRoutes.login ||
        state.matchedLocation == AppRoutes.register;

    // not logged in → force login
    if (user == null && !isAuthPage) return AppRoutes.login;

    // logged in → block login/register
    if (user != null && isAuthPage) return AppRoutes.home;

    return null;
  }
}
