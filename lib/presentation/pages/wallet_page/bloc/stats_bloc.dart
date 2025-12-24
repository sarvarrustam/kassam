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
    on<StatsGetDebtorsCreditors>(_onGetDebtorsCreditors);
    on<StatsCreateDebtorCreditor>(_onCreateDebtorCreditor);
    on<StatsCreateTransactionDebt>(_onCreateTransactionDebt);
    on<StatsCreateTransactionConversion>(_onCreateTransactionConversion);
//  on<StatsCreateDebtorCreditor>(_onCreateDebtorCreditor);
//     on<StatsCreateTransactionDebt>(_onCreateTransactionDebt);  

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
        currency: event.currency,
        exchangeRate: event.exchangeRate, // Tranzaksiya qilingan paytdagi kurs
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

  Future<void> _onGetDebtorsCreditors(
    StatsGetDebtorsCreditors event,
    Emitter<StatsState> emit,
  ) async {
    try {
      print('👥 Getting debtors/creditors list');

      final response = await _apiService.getDebtorsCreditorsList();

      print('👥 Debtors/creditors response: $response');

      if (response['success'] == true) {
        final data = response['data'];
        print('👥 Debtors/creditors data: $data');

        emit(StatsDebtorsCreditorsLoaded(data: data));
      } else {
        final errorMsg = response['error'] ?? 'Qarzkorlar ro\'yxatini yuklashda xatolik';
        emit(StatsError(errorMsg));
      }
    } catch (e, stackTrace) {
      print('❌ Exception: $e');
      print('Stack trace: $stackTrace');
      emit(StatsError('Xatolik: ${e.toString()}'));
    }
  }

  Future<void> _onCreateDebtorCreditor(
    StatsCreateDebtorCreditor event,
    Emitter<StatsState> emit,
  ) async {
    try {
      final result = await _apiService.createDebtorCreditor(
        name: event.name,
        telephoneNumber: event.telephoneNumber,
      );

      if (result['success']) {
        emit(StatsDebtorCreditorCreated(
          message: result['message'],
          data: result['data'],
        ));
      } else {
        emit(StatsError(result['message']));
      }
    } catch (e) {
      emit(StatsError('Xatolik: ${e.toString()}'));
    }
  }

  Future<void> _onCreateTransactionDebt(
    StatsCreateTransactionDebt event,
    Emitter<StatsState> emit,
  ) async {
    try {
      emit(const StatsLoading());
      
      print('💰 Creating transaction debt: ${event.type}, amount: ${event.amount}');
      
      final result = await _apiService.createTransactionDebt(
        //transactionTypesId: event.transactionTypesId,
        type: event.type,
        walletId: event.walletId,
        debtorCreditorId: event.debtorCreditorId,
        previousDebt: event.previousDebt,
        currency: event.currency,
        amount: event.amount,
        amountDebt: event.amountDebt,
        comment: event.comment,
      );

      if (result['success']) {
        emit(StatsTransactionDebtCreated(
          message: result['message'],
          data: result['data'],
        ));
      } else {
        emit(StatsError(result['message']));
      }
    } catch (e) {
      emit(StatsError('Xatolik: ${e.toString()}'));
    }
  }

  Future<void> _onCreateTransactionConversion(
    StatsCreateTransactionConversion event,
    Emitter<StatsState> emit,
  ) async {
    try {
      emit(const StatsLoading());
      
      print('💱 Creating conversion: ${event.amountChiqim} → ${event.amountKirim}');
      
      final result = await _apiService.createTransactionConversion(
        walletIdChiqim: event.walletIdChiqim,
        walletIdKirim: event.walletIdKirim,
        amountChiqim: event.amountChiqim,
        amountKirim: event.amountKirim,
        comment: event.comment,
      );

      if (result['success']) {
        print('💱 ✅ Conversion API SUCCESS!');
        print('💱 📝 Response data: ${result['data']}');
        print('💱 💬 Message: ${result['message']}');
        emit(StatsTransactionCreatedSuccess(
          message: result['message'] ?? 'Konvertatsiya muvaffaqiyatli yaratildi',
        ));
      } else {
        print('💱 ❌ Conversion API FAILED!');
        print('💱 📝 Response: $result');
        emit(StatsError(result['message'] ?? 'Konvertatsiya yaratishda xatolik'));
      }
    } catch (e) {
      emit(StatsError('Xatolik: ${e.toString()}'));
    }
  }

}
