import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kassam/presentation/routes/app_routes.dart';
import 'package:kassam/presentation/theme/app_theme.dart';
import 'package:kassam/arch/bloc/theme_bloc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (context) => ThemeBloc())],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          return MaterialApp.router(
            title: 'Kassam - Shaxsiy Moliya',
            theme: AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            darkTheme: AppTheme.darkTheme,
            themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            routerDelegate: appRouter.routerDelegate,
            routeInformationParser: appRouter.routeInformationParser,
            routeInformationProvider: appRouter.routeInformationProvider,
          );
        },
      ),
    );
  }
}
