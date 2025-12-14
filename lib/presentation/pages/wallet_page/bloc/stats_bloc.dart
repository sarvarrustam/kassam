import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kassam/data/services/api_service.dart';

part 'stats_event.dart';
part 'stats_state.dart';

class StatsBloc extends Bloc<StatsEvent, StatsState> {
  final ApiService _apiService = ApiService();

  StatsBloc() : super(const StatsInitial()) {
    on<StatsCreateTransactionEvent>(_onCreateTransaction);
    on<StatsGetTransactionTypesEvent>(_onGetTransactionTypes);
    on<StatsCreateTransactionTypeEvent>(_onCreateTransactionType);
    on<StatsGetTransactionsEvent>(_onGetTransactions);
    on<StatsGetWalletBalanceEvent>(_onGetWalletBalance);
  }

  Future<void> _onCreateTransaction(
    StatsCreateTransactionEvent event,
    Emitter<StatsState> emit,
  ) async {
    try {
      emit(const StatsLoading());
      
      print('📝 Creating transaction: type=${event.type}, amount=${event.amount}');
      
      final response = await _apiService.createTransaction(
        walletId: event.walletId,
        transactionTypesId: event.transactionTypesId,
        type: event.type,
        comment: event.comment,
        amount: event.amount,
      );

      print('📝 Transaction Response: $response');

      if (response['success'] == true) {
        emit(StatsTransactionCreatedSuccess(
          message: response['message'] ?? 'Tranzaksiya saqlandi',
        ));
      } else {
        final errorMsg = response['error'] ?? 'Tranzaksiya qo\'shishda xatolik';
        print('❌ Error: $errorMsg');
        emit(StatsError(errorMsg));
      }
    } catch (e, stackTrace) {
      print('❌ Exception: $e');
      print('Stack trace: $stackTrace');
      emit(StatsError('Xatolik: ${e.toString()}'));
    }
  }

  Future<void> _onGetTransactionTypes(
    StatsGetTransactionTypesEvent event,
    Emitter<StatsState> emit,
  ) async {
    try {
      emit(const StatsLoading());
      
      print('📊 Getting transaction types: ${event.type}...');
      
      final response = await _apiService.getTransactionTypesData(event.type);

      print('📊 Transaction Types Response: $response');

      if (response['success'] == true && response['data'] != null) {
        emit(StatsTransactionTypesLoaded(
          data: response['data'],
        ));
      } else {
        final errorMsg = response['error'] ?? 'Tranzaksiya turlarini olishda xatolik';
        print('❌ Error: $errorMsg');
        emit(StatsError(errorMsg));
      }
    } catch (e, stackTrace) {
      print('❌ Exception: $e');
      print('Stack trace: $stackTrace');
      emit(StatsError('Xatolik: ${e.toString()}'));
    }
  }

  Future<void> _onCreateTransactionType(
    StatsCreateTransactionTypeEvent event,
    Emitter<StatsState> emit,
  ) async {
    try {
      emit(const StatsLoading());

      print('➕ Creating transaction type: ${event.name} (${event.type})');

      final response = await _apiService.createTransactionType(
        name: event.name,
        type: event.type,
      );

      print('➕ Transaction type response: $response');

      if (response['success'] == true) {
        emit(StatsTransactionTypeCreatedSuccess(
          message: response['message'] ?? 'Tranzaksiya turi qo\'shildi',
          data: response['data'],
        ));
      } else {
        final errorMsg =
            response['error'] ?? 'Tranzaksiya turini qo\'shishda xatolik';
        emit(StatsError(errorMsg));
      }
    } catch (e, stackTrace) {
      print('❌ Exception: $e');
      print('Stack trace: $stackTrace');
      emit(StatsError('Xatolik: ${e.toString()}'));
    }
  }

  Future<void> _onGetTransactions(
    StatsGetTransactionsEvent event,
    Emitter<StatsState> emit,
  ) async {
    try {
      emit(const StatsLoading());

      print('📊 Getting transactions: walletId=${event.walletId}');

      final response = await _apiService.getTransactions(
        walletId: event.walletId,
        fromDate: event.fromDate,
        toDate: event.toDate,
      );

      print('📊 Transactions response: $response');

      if (response['success'] == true) {
        emit(StatsTransactionsLoaded(data: response['data']));
      } else {
        final errorMsg = response['error'] ?? 'Tranzaksiyalarni yuklashda xatolik';
        emit(StatsError(errorMsg));
      }
    } catch (e, stackTrace) {
      print('❌ Exception: $e');
      print('Stack trace: $stackTrace');
      emit(StatsError('Xatolik: ${e.toString()}'));
    }
  }

  Future<void> _onGetWalletBalance(
    StatsGetWalletBalanceEvent event,
    Emitter<StatsState> emit,
  ) async {
    try {
      print('💰 Getting wallet balance: walletId=${event.walletId}');

      final response = await _apiService.getWalletBalanceData(
        walletId: event.walletId,
        fromDate: event.fromDate,
        toDate: event.toDate,
      );

      print('💰 Wallet balance response: $response');

      if (response['success'] == true) {
        final data = response['data'];
        print('💰 Balance data: $data');
        
        // API strukturasi: balance, inflow, outflow
        final kirimTotal = (data['inflow'] ?? 0).toDouble();
        final chiqimTotal = (data['outflow'] ?? 0).toDouble();
        final walletBalance = (data['balance'] ?? 0).toDouble();
        
        print('💰 Kirim total (inflow): $kirimTotal');
        print('💰 Chiqim total (outflow): $chiqimTotal');
        print('💰 Wallet balance: $walletBalance');

        emit(StatsWalletBalanceLoaded(
          kirimTotal: kirimTotal,
          chiqimTotal: chiqimTotal,
          walletBalance: walletBalance,
        ));
      } else {
        final errorMsg = response['error'] ?? 'Hamyon balansi yuklashda xatolik';
        emit(StatsError(errorMsg));
      }
    } catch (e, stackTrace) {
      print('❌ Exception: $e');
      print('Stack trace: $stackTrace');
      emit(StatsError('Xatolik: ${e.toString()}'));
    }
  }

}
