part of 'home_bloc.dart';

class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeWalletsLoading extends HomeState {}

class HomeTotalBalancesLoading extends HomeState {}

class HomeGetWalletsSuccess extends HomeState {
  final List<WalletBalance> wallets;
  const HomeGetWalletsSuccess(this.wallets);

  @override
  List<Object> get props => [wallets];
}

class HomeGetTotalBalancesSuccess extends HomeState {
  final double somTotal;
  final double dollarTotal;
  
  const HomeGetTotalBalancesSuccess({
    required this.somTotal,
    required this.dollarTotal,
  });

  @override
  List<Object> get props => [somTotal, dollarTotal];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);

  @override
  List<Object> get props => [message];
}

class HomeWalletCreatedSuccess extends HomeState {}

class HomeGetExchangeRateSuccess extends HomeState {
  final double rate;
  const HomeGetExchangeRateSuccess(this.rate);

  @override
  List<Object> get props => [rate];
}
