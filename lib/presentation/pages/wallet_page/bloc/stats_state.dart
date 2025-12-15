part of 'stats_bloc.dart';

abstract class StatsState extends Equatable {
  const StatsState();

  @override
  List<Object?> get props => [];
}

class StatsInitial extends StatsState {
  const StatsInitial();
}

class StatsLoading extends StatsState {
  const StatsLoading();
}

class StatsTransactionCreatedSuccess extends StatsState {
  final String message;

  const StatsTransactionCreatedSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class StatsTransactionTypesLoaded extends StatsState {
  final dynamic data;

  const StatsTransactionTypesLoaded({required this.data});

  @override
  List<Object?> get props => [data];
}

class StatsTransactionTypeCreatedSuccess extends StatsState {
  final String message;
  final dynamic data;

  const StatsTransactionTypeCreatedSuccess({
    required this.message,
    this.data,
  });

  @override
  List<Object?> get props => [message, data];
}

class StatsTransactionsLoaded extends StatsState {
  final dynamic data;

  const StatsTransactionsLoaded({required this.data});

  @override
  List<Object?> get props => [data];
}

class StatsError extends StatsState {
  final String message;

  const StatsError(this.message);

  @override
  List<Object?> get props => [message];
}

class StatsWalletBalanceLoaded extends StatsState {
  final double kirimTotal;
  final double chiqimTotal;
  final double walletBalance; // API'dan kelgan to'g'ridan-to'g'ri balance

  const StatsWalletBalanceLoaded({
    required this.kirimTotal,
    required this.chiqimTotal,
    required this.walletBalance,
  });

  @override
  List<Object?> get props => [kirimTotal, chiqimTotal, walletBalance];
}
  
  