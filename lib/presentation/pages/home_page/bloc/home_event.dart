part of 'home_bloc.dart';

class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

class HomeGetWalletsEvent extends HomeEvent {}

class HomeGetTotalBalancesEvent extends HomeEvent {}

class HomeGetInitialDataEvent extends HomeEvent {}

class HomeCreateWalletEvent extends HomeEvent {
  final String name;
  final String currency;

  const HomeCreateWalletEvent({
    required this.name,
    required this.currency,
  });

  @override
  List<Object> get props => [name, currency];
}

class HomeGetExchangeRateEvent extends HomeEvent {}

class HomeUpdateExchangeRateEvent extends HomeEvent {
  final double kurs;

  const HomeUpdateExchangeRateEvent({required this.kurs});

  @override
  List<Object> get props => [kurs];
}  