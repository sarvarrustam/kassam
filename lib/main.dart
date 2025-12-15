import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kassam/presentation/routes/app_routes.dart';
import 'package:kassam/data/services/app_preferences_service.dart';
import 'package:kassam/data/services/api_service.dart';
import 'package:kassam/presentation/theme/app_theme.dart';
import 'package:kassam/arch/bloc/theme_bloc.dart';
import 'package:kassam/presentation/pages/entry_pages/bloc/auth_bloc.dart';
import 'package:kassam/presentation/pages/home_page/bloc/home_bloc.dart';
import 'package:kassam/presentation/blocs/user/user_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:kassam/presentation/pages/version/version_blocker_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = AppPreferencesService();
  await prefs.initialize();

  // VERSIYA TEKSHIRUVI - Dastur boshlanishida
  final versionCheckResult = await _checkVersionBeforeStart(prefs);
  if (versionCheckResult != null) {
    runApp(VersionBlockerPage(
      currentVersion: versionCheckResult['current']!,
      requiredVersion: versionCheckResult['required']!,
    ));
    return;
  }
  runApp(const MyApp());
}

// Dastur boshlanishidan oldin versiyani tekshirish
Future<Map<String, int>?> _checkVersionBeforeStart(AppPreferencesService prefs) async {
  try {
    final token = await prefs.getAuthToken();
    if (token == null || token.isEmpty) {
      print('⚠️ Main: No token, skipping version check');
      return null;
    }
    
    // Hozirgi app versiyasini olish
    final packageInfo = await PackageInfo.fromPlatform();
    final versionParts = packageInfo.version.split('.');
    final currentVersion = int.tryParse(versionParts.first) ?? 1;
    
    print('📱 Main: Current app version: ${packageInfo.version} (major: $currentVersion)');
    
    // Serverdan versiyani olish
    final apiService = ApiService();
    final response = await apiService.get(
      'Kassam/hs/KassamUrl/getUser',
      token: token,
    );
    
    if (response['error'] == false && response['data'] != null) {
      final serverVersion = response['data']['version'] as int?;
      
      if (serverVersion != null) {
        print('📦 Main: Server version: $serverVersion');
        
        if (currentVersion < serverVersion) {
          // Versiya eski - dasturni to'xtatish
          print('❌ Main: Version outdated! Current=$currentVersion, Required=$serverVersion');
          print('🚫 Main: APP MUST BE UPDATED! Blocking UI...');
          return {'current': currentVersion, 'required': serverVersion};
        }
        
        print('✅ Main: Version compatible, continuing...');
      }
    }
  } catch (e) {
    print('⚠️ Main: Version check error: $e');
    // Xatolik bo'lsa davom etish
  }
  return null;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ThemeBloc()),
        BlocProvider(create: (context) => AuthBloc()),
        BlocProvider(create: (context) => HomeBloc()),
        BlocProvider(create: (context) => UserBloc()),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          return MaterialApp.router(
            title: 'Kassam - Shaxsiy Moliya',
            theme: AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            darkTheme: AppTheme.darkTheme,
            themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('uz', 'UZ'), // O'zbek
              Locale('ru', 'RU'), // Rus
              Locale('en', 'US'), // Ingliz
            ],
            locale: const Locale('uz', 'UZ'),
            routerDelegate: appRouter.routerDelegate,
            routeInformationParser: appRouter.routeInformationParser,
            routeInformationProvider: appRouter.routeInformationProvider,
          );
        },
      ),
    );
  }
}
