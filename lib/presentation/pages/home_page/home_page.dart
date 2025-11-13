import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kassam/arch/bloc/transaction_cubit.dart';
import 'package:kassam/arch/bloc/transaction_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TransactionCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => cubit.loadMockTransactions(),
        child: const Icon(Icons.refresh),
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
                  title: Text(t.title),
                  subtitle: Text(t.category),
                  trailing: Text(t.amount.toStringAsFixed(2)),
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
