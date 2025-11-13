import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kassam/data/models/transaction.dart';
import 'transaction_state.dart';

class TransactionCubit extends Cubit<TransactionState> {
  TransactionCubit() : super(const TransactionInitial());

  // Mock ma'lumotlar
  final List<Transaction> _mockTransactions = [
    Transaction(
      id: '1',
      title: 'Oylik maosh',
      amount: 5000000,
      date: DateTime.now(),
      type: TransactionType.income,
      category: 'Maosh',
    ),
    Transaction(
      id: '2',
      title: 'Elektr qarori',
      amount: 150000,
      date: DateTime.now(),
      type: TransactionType.expense,
      category: 'Komunal',
    ),
    Transaction(
      id: '3',
      title: 'Kiyim sotib olish',
      amount: 300000,
      date: DateTime.now(),
      type: TransactionType.expense,
      category: 'Xarid',
    ),
  ];

  // Barcha tranzaksiyalarni yuklash
  Future<void> loadTransactions() async {
    emit(const TransactionLoading());
    try {
      // Simulyatsiya delay
      await Future.delayed(const Duration(milliseconds: 500));
      emit(TransactionLoaded(_mockTransactions));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  // Mock tranzaksiyalarni yuklash (eski nomi saqlab turamiz)
  Future<void> loadMockTransactions() async {
    await loadTransactions();
  }

  // Yangi tranzaksiya qo'shish
  Future<void> addTransaction(Transaction transaction) async {
    if (state is TransactionLoaded) {
      final currentTransactions = (state as TransactionLoaded).transactions
          .toList();
      currentTransactions.add(transaction);
      emit(TransactionLoaded(currentTransactions));
    }
  }

  // Tranzaksiyani o'chirish
  Future<void> deleteTransaction(String id) async {
    if (state is TransactionLoaded) {
      final currentTransactions = (state as TransactionLoaded).transactions
          .toList();
      currentTransactions.removeWhere((transaction) => transaction.id == id);
      emit(TransactionLoaded(currentTransactions));
    }
  }
}
