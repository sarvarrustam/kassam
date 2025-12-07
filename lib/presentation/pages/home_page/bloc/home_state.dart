part of 'home_bloc.dart';

class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
}

// Boshlang'ich holat
final class HomeInitial extends HomeState {}

// Ma'lumotlar yuklanmoqda
final class HomeLoading extends HomeState {}

// Ma'lumotlar yuklandi
final class HomeLoaded extends HomeState {
  final String userName;
  final String phoneNumber;
  final double? totalUZS;
  final double? totalUSD;
  final List<Map<String, dynamic>>? wallets;

  const HomeLoaded({
    required this.userName,
    required this.phoneNumber,
    this.totalUZS,
    this.totalUSD,
    this.wallets,
  });

  @override
  List<Object> get props => [
    userName, 
    phoneNumber,
    totalUZS ?? 0,
    totalUSD ?? 0,
    wallets ?? [],
  ];
  
  // copyWith method for updating partial data
  HomeLoaded copyWith({
    String? userName,
    String? phoneNumber,
    double? totalUZS,
    double? totalUSD,
    List<Map<String, dynamic>>? wallets,
  }) {
    return HomeLoaded(
      userName: userName ?? this.userName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      totalUZS: totalUZS ?? this.totalUZS,
      totalUSD: totalUSD ?? this.totalUSD,
      wallets: wallets ?? this.wallets,
    );
  }
}

// Xatolik
final class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object> get props => [message];
}
