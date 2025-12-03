import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../pages/entry_pages/entry_page.dart';
import '../pages/entry_pages/registration_pages/phone_registration_page.dart';
import '../pages/entry_pages/registration_pages/sms_verification_page.dart';
import '../pages/entry_pages/registration_pages/create_user_page.dart';
import '../pages/home_page/home_page.dart';
import '../pages/stats_page.dart';
import '../pages/settings_page.dart';
import '../pages/add_transaction_page.dart';
import '../pages/transactions_list_page.dart';
import '../pages/wallet_page.dart';
import '../../data/services/app_preferences_service.dart';

// RootLayout - Bottom Navigation Bar va Floating Action Button bilan
class RootLayout extends StatefulWidget {
  final Widget child;
  final String currentLocation;

  const RootLayout({
    required this.child,
    required this.currentLocation,
    super.key,
  });

  @override
  State<RootLayout> createState() => _RootLayoutState();
}

class _RootLayoutState extends State<RootLayout> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _updateSelectedIndex();
  }

  @override
  void didUpdateWidget(RootLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLocation != widget.currentLocation) {
      _updateSelectedIndex();
    }
  }

  void _updateSelectedIndex() {
    switch (widget.currentLocation) {
      case '/home':
        _selectedIndex = 0;
        break;
      case '/stats':
        _selectedIndex = 1;
        break;
      case '/wallet':
        _selectedIndex = 2;
        break;
      case '/settings':
        _selectedIndex = 3;
        break;
      default:
        _selectedIndex = 0;
    }
  }

  void _onItemTapped(int index) {
    final routes = ['/home', '/stats', '/wallet', '/settings'];
    context.go(routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: const Text('Kassam'), elevation: 11),
      body: widget.child,
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     context.push('/add-transaction');
      //   },
      //   elevation: 4,
      //   child: const Icon(Icons.add),
      // ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Bosh',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wallet_outlined),
            activeIcon: Icon(Icons.wallet),
            label: 'Hamyon',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Statistika',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Sozlamalar',
          ),
        ],
      ),
    );
  }
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/entry',
  redirect: (context, state) async {
    final prefs = AppPreferencesService();
    final hasCompleted = await prefs.hasCompletedOnboarding();

   

    // Auth route larni aniqlash
    final isAuthRoute =
        state.matchedLocation == '/entry' ||
        state.matchedLocation == '/phone-input' ||
        state.matchedLocation == '/sms-verification' ||
        state.matchedLocation == '/create-user';

    // Agar onboarding tugallanmagan bo'lsa va auth route emas bo'lsa
    // Entry sahifasiga yo'naltirish
    if (!hasCompleted && !isAuthRoute) {
     
      return '/entry';
    }

    // YANGI: SMS verification va create-user'dan keyin home/register'ga o'tishga ruxsat berish
    // Bu route'lardan redirect qilmaslik
    if (state.matchedLocation == '/sms-verification' || 
        state.matchedLocation == '/create-user') {
      
      return null;
    }

    // Agar onboarding tugallangan bo'lsa va entry/phone-input'da bo'lsa
    // Home sahifasiga yo'naltirish
    if (hasCompleted && (state.matchedLocation == '/entry' || state.matchedLocation == '/phone-input')) {
     
      return '/home';
    }

    
    return null;
  },
  routes: <RouteBase>[
    // Auth Routes (Entry Pages - without Bottom Navigation)
    GoRoute(
      path: '/entry',
      name: 'entry',
      builder: (context, state) => const EntryPage(),
    ),
    GoRoute(
      path: '/phone-input',
      name: 'phone-input',
      builder: (context, state) => const PhoneRegistrationPage(),
    ),
    GoRoute(
      path: '/sms-verification',
      name: 'sms-verification',
      builder: (context, state) {
        final phoneNumber = state.extra as String? ?? '';
        return SmsVerificationPage(phoneNumber: phoneNumber);
      },
    ),
    GoRoute(
      path: '/create-user',
      name: 'create-user',
      builder: (context, state) {
        final phoneNumber = state.extra as String? ?? '';
        return CreateUserPage(phoneNumber: phoneNumber);
      },
    ),

    // Add Transaction Route (Modal)
    GoRoute(
      path: '/add-transaction',
      name: 'add-transaction',
      builder: (context, state) => const AddTransactionPage(),
    ),

    // Transactions List Route
    GoRoute(
      path: '/transactions-list',
      name: 'transactions-list',
      builder: (context, state) => const TransactionsListPage(),
    ),

    // Main App Routes (with Bottom Navigation Bar)
    ShellRoute(
      builder: (context, state, child) {
        return RootLayout(currentLocation: state.matchedLocation, child: child);
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
          builder: (context, state) {
            final walletId = state.uri.queryParameters['walletId'];
            return StatsPage(walletId: walletId);
          },
        ),
        GoRoute(
          path: '/wallet',
          name: 'wallet',
          builder: (context, state) => const WalletPage(),
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
