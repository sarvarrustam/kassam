import 'package:bloc/bloc.dart';
import 'package:kassam/data/models/transaction.dart';
import 'transaction_state.dart';

class TransactionCubit extends Cubit<TransactionState> {
  TransactionCubit() : super(TransactionLoading());

  Future<void> loadMockTransactions() async {
    try {
      emit(TransactionLoading());
      await Future.delayed(const Duration(milliseconds: 500));

      final items = List.generate(6, (i) {
        return Transaction(
          id: 't$i',
          title: i % 2 == 0 ? 'Salary' : 'Coffee',
          amount: i % 2 == 0 ? 1200.0 + i : 3.5 + i,
          date: DateTime.now().subtract(Duration(days: i)),
          type: i % 2 == 0 ? TransactionType.income : TransactionType.expense,
          category: i % 2 == 0 ? 'Income' : 'Food',
        );
      });

      emit(TransactionLoaded(items));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }
}
