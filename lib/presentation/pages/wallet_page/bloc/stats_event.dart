part of 'stats_bloc.dart';

abstract class StatsEvent extends Equatable {
  const StatsEvent();

  @override
  List<Object?> get props => [];
}

/// Transaction qo'shish event (yangi format)
class StatsCreateTransactionEvent extends StatsEvent {
  final String walletId;
  final String transactionTypesId;
  final String type; // 'chiqim' yoki 'kirim'
  final String comment;
  final double amount;

  const StatsCreateTransactionEvent({
    required this.walletId,
    required this.transactionTypesId,
    required this.type,
    required this.comment,
    required this.amount, required String currency,
  });

  @override
  List<Object?> get props => [walletId, transactionTypesId, type, comment, amount];
}

/// Transaction turlarini olish event
class StatsGetTransactionTypesEvent extends StatsEvent {
  final String type; // 'chiqim' yoki 'kirim'
  
  const StatsGetTransactionTypesEvent({required this.type});

  @override
  List<Object?> get props => [type];
}

/// Yangi transaction turini yaratish
class StatsCreateTransactionTypeEvent extends StatsEvent {
  final String name;
  final String type; // 'chiqim' yoki 'kirim'

  const StatsCreateTransactionTypeEvent({
    required this.name,
    required this.type,
  });

  @override
  List<Object?> get props => [name, type];
}

/// Tranzaksiyalarni olish event
class StatsGetTransactionsEvent extends StatsEvent {
  final String walletId;
  final String fromDate; // Format: dd.MM.yyyy
  final String toDate;   // Format: dd.MM.yyyy

  const StatsGetTransactionsEvent({
    required this.walletId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  List<Object?> get props => [walletId, fromDate, toDate];
}

/// Hamyon balansi statistikasini olish event
class StatsGetWalletBalanceEvent extends StatsEvent {
  final String walletId;
  final String fromDate; // Format: dd.MM.yyyy
  final String toDate;   // Format: dd.MM.yyyy

  const StatsGetWalletBalanceEvent({
    required this.walletId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  List<Object?> get props => [walletId, fromDate, toDate];
}

/// Qarzkorlar va kreditorlar ro'yxatini olish event
class StatsGetDebtorsCreditors extends StatsEvent {
  const StatsGetDebtorsCreditors();

  @override
  List<Object?> get props => [];
}

/// Yangi qarzkor/kreditor yaratish event
class StatsCreateDebtorCreditor extends StatsEvent {
  final String name;
  final String telephoneNumber;
  
  const StatsCreateDebtorCreditor({
    required this.name,
    required this.telephoneNumber,
  });

  @override
  List<Object?> get props => [name, telephoneNumber];
}



/// Qarz operatsiyasini yaratish event
class StatsCreateTransactionDebt extends StatsEvent {
  //final String transactionTypesId;
  final String type; // qarzPulBerish, qarzPulOlish
  final String walletId;
  final String debtorCreditorId;
  final bool previousDebt;
  final String currency; // uzs, usd
  final double amount;
  final double amountDebt;
  final String? comment;

  const StatsCreateTransactionDebt({
    //required this.transactionTypesId,
    required this.type,
    required this.walletId,
    required this.debtorCreditorId,
    required this.previousDebt,
    required this.currency,
    required this.amount,
    required this.amountDebt,
    this.comment,
  });

  @override
  List<Object?> get props => [
    //transactionTypesId,
    type,
    walletId,
    debtorCreditorId,
    previousDebt,
    currency,
    amount,
    amountDebt,
    comment,
  ];
}
