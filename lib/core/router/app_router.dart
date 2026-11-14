import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "../config/supabase_config.dart";
import "../../features/auth/presentation/login_screen.dart";
import "../../features/customers/presentation/customer_history_screen.dart";
import "../../features/dashboard/presentation/main_shell_screen.dart";

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: "/login",
  redirect: (BuildContext context, GoRouterState state) {
    final client = SupabaseConfig.client;
    final isLoggedIn = client?.auth.currentUser != null;
    final isLoggingIn = state.matchedLocation == "/login";

    if (isLoggedIn && isLoggingIn) {
      return "/dashboard";
    }
    return null;
  },
  routes: [
    GoRoute(
      path: "/login",
      builder: (BuildContext context, GoRouterState state) {
        return const LoginScreen();
      },
    ),
    GoRoute(
      path: "/dashboard",
      builder: (BuildContext context, GoRouterState state) {
        return const MainShellScreen();
      },
    ),
    GoRoute(
      path: "/customers",
      builder: (BuildContext context, GoRouterState state) {
        return Consumer(
          builder: (context, ref, _) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(navigationIndexProvider.notifier).setIndex(1);
            });
            return const MainShellScreen();
          },
        );
      },
    ),
    GoRoute(
      path: "/works",
      builder: (BuildContext context, GoRouterState state) {
        return Consumer(
          builder: (context, ref, _) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(navigationIndexProvider.notifier).setIndex(2);
            });
            return const MainShellScreen();
          },
        );
      },
    ),
    GoRoute(
      path: "/payments",
      builder: (BuildContext context, GoRouterState state) {
        return Consumer(
          builder: (context, ref, _) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(navigationIndexProvider.notifier).setIndex(3);
            });
            return const MainShellScreen();
          },
        );
      },
    ),
    GoRoute(
      path: "/reports",
      builder: (BuildContext context, GoRouterState state) {
        return Consumer(
          builder: (context, ref, _) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(navigationIndexProvider.notifier).setIndex(4);
            });
            return const MainShellScreen();
          },
        );
      },
    ),
    GoRoute(
      path: "/settings",
      builder: (BuildContext context, GoRouterState state) {
        return Consumer(
          builder: (context, ref, _) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(navigationIndexProvider.notifier).setIndex(5);
            });
            return const MainShellScreen();
          },
        );
      },
    ),
    GoRoute(
      path: "/history",
      builder: (BuildContext context, GoRouterState state) {
        return const CustomerHistoryScreen();
      },
    ),
  ],
);
