import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kassam/presentation/routes/app_routes.dart';
import 'package:kassam/data/services/app_preferences_service.dart';
import 'package:kassam/presentation/theme/app_theme.dart';
import 'package:kassam/arch/bloc/theme_bloc.dart';
import 'package:kassam/presentation/pages/entry_pages/bloc/auth_bloc.dart';
import 'package:kassam/presentation/pages/home_page/bloc/home_bloc.dart';
import 'package:kassam/presentation/blocs/user/user_bloc.dart';
import 'package:kassam/data/services/api_service.dart';
import 'package:kassam/presentation/widgets/global_http_inspector_button.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPreferencesService().initialize();
  
  // Alice uchun navigatorKey o'rnatish (go_router'dan)
  ApiService.alice.setNavigatorKey(appRouter.routerDelegate.navigatorKey);
  
  runApp(const MyApp());
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
            builder: (context, child) {
              return Stack(
                children: [
                  child ?? const SizedBox.shrink(),
                  const GlobalHttpInspectorButton(),
                ],
              );
            },

            // home: const EntryPage(  tetettegdvdttttettet
          );
        },
      ),
    );
  }
}
