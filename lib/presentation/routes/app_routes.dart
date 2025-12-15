import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../pages/splash_page/splash_page.dart';
import '../pages/entry_pages/entry_page.dart';
import '../pages/entry_pages/registration_pages/phone_registration_page.dart';
import '../pages/entry_pages/registration_pages/sms_verification_page.dart';
import '../pages/entry_pages/registration_pages/create_user_page.dart';
import '../pages/security/pin_code_setup_page.dart';
import '../pages/security/pin_code_verify_page.dart';
import '../pages/version/version_update_page.dart';
import '../pages/home_page/home_page.dart';
import '../pages/wallet_page/stats_page.dart';
import '../pages/profile_setings/settings_page.dart';
import '../pages/diagram_page.dart';
import '../pages/wallet_page/add_transaction_page.dart';
import '../pages/transactions_list_page.dart';
import '../../data/services/app_preferences_service.dart';
import '../../data/services/api_service.dart';

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
      case '/diagram':
        _selectedIndex = 1;
        break;
      case '/settings':
        _selectedIndex = 2;
        break;
      default:
        _selectedIndex = 3;
    }
  }

  void _onItemTapped(int index) {
    final routes = ['/home', '/diagram', '/settings'];
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
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Diagramma',
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
  initialLocation: '/splash',
  redirect: (context, state) async {
    // Splash va version-update page'dan redirect qilmaslik
    if (state.matchedLocation == '/splash' || 
        state.matchedLocation == '/version-update') {
      return null;
    }

    final prefs = AppPreferencesService();
    final hasCompleted = await prefs.hasCompletedOnboarding();
    final token = await prefs.getAuthToken();

    // VERSIYA TEKSHIRUVI - Eng muhim!
    if (token != null && token.isNotEmpty) {
      try {
        // Hozirgi app versiyasini olish
        final packageInfo = await PackageInfo.fromPlatform();
        final versionParts = packageInfo.version.split('.');
        final currentVersion = int.tryParse(versionParts.first) ?? 1;
        
        // Serverdan versiyani olish
        final apiService = ApiService();
        final response = await apiService.get(
          'Kassam/hs/KassamUrl/getUser',
          token: token,
        );
        
        if (response['error'] == false && response['data'] != null) {
          final serverVersion = response['data']['version'] as int?;
          
          if (serverVersion != null && currentVersion < serverVersion) {
            print('❌ Router: Version outdated! Current=$currentVersion, Server=$serverVersion');
            // Versiya eski - version update sahifasiga yo'naltirish
            return '/version-update?current=$currentVersion&required=$serverVersion';
          }
        }
      } catch (e) {
        print('⚠️ Router: Version check error: $e');
      }
    }

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
    // Splash Screen
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashPage(),
    ),
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
    // PIN Code Routes
    GoRoute(
      path: '/pin-setup',
      name: 'pin-setup',
      builder: (context, state) => const PinCodeSetupPage(),
    ),
    GoRoute(
      path: '/pin-verify',
      name: 'pin-verify',
      builder: (context, state) => const PinCodeVerifyPage(),
    ),

    // Version Update Route
    GoRoute(
      path: '/version-update',
      name: 'version-update',
      builder: (context, state) {
        final currentVersion = int.tryParse(state.uri.queryParameters['current'] ?? '1') ?? 1;
        final requiredVersion = int.tryParse(state.uri.queryParameters['required'] ?? '1') ?? 1;
        return VersionUpdateRequiredPage(
          currentVersion: currentVersion,
          requiredVersion: requiredVersion,
        );
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
          path: '/diagram',
          name: 'diagram',
          builder: (context, state) => const DiagramPage(),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsPage(),
        ),
      ],
    ),

    // Stats Page Route (Modal - without Bottom Navigation)
    GoRoute(
      path: '/stats',
      name: 'stats',
      builder: (context, state) {
        final walletId = state.uri.queryParameters['walletId'];
        final walletName = state.uri.queryParameters['walletName'];
        final walletCurrency = state.uri.queryParameters['walletCurrency'];
        return StatsPage(
          walletId: walletId, 
          walletName: walletName,
          walletCurrency: walletCurrency,
        );
      },
    ),
  ],
);
