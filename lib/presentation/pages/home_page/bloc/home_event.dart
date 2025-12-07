part of 'home_bloc.dart';

class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

// Home page ochilganda user ma'lumotlarini yuklash
final class HomeLoadUserData extends HomeEvent {}

// Ma'lumotlarni yangilash (refresh)
final class HomeRefreshData extends HomeEvent {}

// Wallet balanslarini yuklash
final class HomeLoadWalletBalances extends HomeEvent {}

// Hamyonlar ro'yxatini yuklash
final class HomeLoadWallets extends HomeEvent {}
