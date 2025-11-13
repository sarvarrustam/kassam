import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kassam/presentation/pages/home_page/home_page.dart';
import 'package:kassam/presentation/pages/stats_page/stats_page.dart';
import 'package:kassam/presentation/pages/budget_page/budget_page.dart';
import 'package:kassam/presentation/pages/settings_page/settings_page.dart';
import 'package:kassam/presentation/pages/auth_pages/phone_input_page.dart';
import 'package:kassam/presentation/pages/auth_pages/otp_verify_page.dart';
import 'package:kassam/presentation/pages/auth_pages/profile_setup_page.dart';

// RootLayout - Bottom Navigation Bar bilan
class RootLayout extends StatefulWidget {
  final Widget child;

  const RootLayout({required this.child, super.key});

  @override
  State<RootLayout> createState() => _RootLayoutState();
}

class _RootLayoutState extends State<RootLayout> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    final routes = ['/home', '/stats', '/budget', '/settings'];
    context.go(routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Bosh'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Statistika',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.wallet), label: 'Byudjet'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Sozlamalar',
          ),
        ],
      ),
    );
  }
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/phone-input',
  routes: <RouteBase>[
    // Auth Routes (Shell bilan emas)
    GoRoute(
      path: '/phone-input',
      name: 'phone-input',
      builder: (context, state) => const PhoneInputPage(),
    ),
    GoRoute(
      path: '/otp-verify',
      name: 'otp-verify',
      builder: (context, state) {
        final phoneNumber = state.extra as String? ?? '';
        return OtpVerifyPage(phoneNumber: phoneNumber);
      },
    ),
    GoRoute(
      path: '/profile-setup',
      name: 'profile-setup',
      builder: (context, state) {
        final phoneNumber = state.extra as String? ?? '';
        return ProfileSetupPage(phoneNumber: phoneNumber);
      },
    ),
    // Main App Routes (Bottom Navigation bar bilan)
    ShellRoute(
      builder: (context, state, child) {
        return RootLayout(child: child);
      },
      routes: [
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
    ),
  ],
);
