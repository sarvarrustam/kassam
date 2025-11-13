import 'package:go_router/go_router.dart';
import 'package:kassam/presentation/pages/home_page/home_page.dart';
import 'package:kassam/presentation/pages/stats_page/stats_page.dart';
import 'package:kassam/presentation/pages/budget_page/budget_page.dart';
import 'package:kassam/presentation/pages/settings_page/settings_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  routes: <GoRoute>[
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/stats',
      name: 'stats',
      builder: (context, state) => const StatsPage(),
    ),
    GoRoute(
      path: '/budget',
      name: 'budget',
      builder: (context, state) => const BudgetPage(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);
