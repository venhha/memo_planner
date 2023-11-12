import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memo_planner/features/habit/presentation/screens/edit_habit_instance_screen.dart';
import 'package:memo_planner/features/habit/presentation/screens/edit_habit_screen.dart';

import '../../core/widgets/widgets.dart';
import '../../features/authentication/presentation/screens/screens.dart';
import '../../features/goal/presentation/screens/goal_page.dart';
import '../../features/habit/presentation/screens/screens.dart';

part 'app_navigation_bar.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

class AppRouters {
  static final GoRouter router = GoRouter(
    debugLogDiagnostics: true, // NOTE only set to true if you need to debug
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/habit',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: '/',
                redirect: (context, state) => '/habit',
              ),
              habitRoutes(),
            ],
          ),
          StatefulShellBranch(
            routes: [
              goalRoutes(),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              authenticationRoutes(),
            ],
          ),
        ],
      )
    ],
  );
}

GoRoute habitRoutes() {
  return GoRoute(
    path: '/habit',
    builder: (context, state) => const HabitPage(),
    routes: [
      GoRoute(
        path: 'add',
        builder: (context, state) => const AddHabitScreen(),
      ),
      GoRoute(
          path: 'detail/:hid',
          builder: (context, state) {
            final hid = state.pathParameters['hid']!;
            return HabitDetailScreen(hid: hid);
          }),
      GoRoute(
          path: 'edit-habit/:id', // this id may be hid or iid
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return EditHabitScreen(hid: id);
          }),
      GoRoute(
          path: 'edit-instance/:id', // this id may be hid or iid
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return EditHabitInstanceScreen(iid: id);
          }),
    ],
  );
}

GoRoute goalRoutes() {
  return GoRoute(
    path: '/goal',
    builder: (context, state) => const GoalPage(),
  );
}

GoRoute authenticationRoutes() {
  return GoRoute(
    path: '/authentication',
    builder: (context, state) => const AuthenticationPage(),
    routes: [
      GoRoute(
        path: 'sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: 'sign-up',
        builder: (context, state) => const SignUpScreen(),
      ),
    ],
  );
}
