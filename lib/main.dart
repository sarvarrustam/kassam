import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kassam/arch/bloc/transaction_cubit.dart';
import 'package:kassam/presentation/routes/app_routes.dart';
import 'package:kassam/presentation/theme/app_theme.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TransactionCubit>(create: (_) => TransactionCubit()),
      ],
      child: MaterialApp.router(
        title: 'Kassam App',
        theme: AppTheme.lightTheme,
        routerDelegate: appRouter.routerDelegate,
        routeInformationParser: appRouter.routeInformationParser,
        routeInformationProvider: appRouter.routeInformationProvider,
      ),
    );
  }
}
