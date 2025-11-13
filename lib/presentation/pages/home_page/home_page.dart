import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kassam/arch/bloc/transaction_cubit.dart';
import 'package:kassam/arch/bloc/transaction_state.dart';
import 'package:kassam/presentation/theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<TransactionCubit>().loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KASSAM')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<TransactionCubit>().loadTransactions(),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TransactionLoaded) {
            return ListView.builder(
              itemCount: state.transactions.length,
              itemBuilder: (context, i) {
                final t = state.transactions[i];
                return ListTile(
                  leading: Icon(
                    t.type.toString().contains('income')
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: t.type.toString().contains('income')
                        ? AppColors.successGreen
                        : AppColors.errorRed,
                  ),
                  title: Text(t.title),
                  subtitle: Text(t.category),
                  trailing: Text(
                    '${t.type.toString().contains('income') ? '+' : '-'} ${t.amount}',
                    style: TextStyle(
                      color: t.type.toString().contains('income')
                          ? AppColors.successGreen
                          : AppColors.errorRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            );
          }
          if (state is TransactionError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
