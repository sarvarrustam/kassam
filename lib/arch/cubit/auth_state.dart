import 'package:equatable/equatable.dart';
import 'package:kassam/data/models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

// Boshlang'ich state
class AuthInitial extends AuthState {
  const AuthInitial();
}

// Yuklanayotgan state
class AuthLoading extends AuthState {
  const AuthLoading();
}

// OTP kodi yuborildi
class OtpSent extends AuthState {
  final String phoneNumber;

  const OtpSent(this.phoneNumber);

  @override
  List<Object?> get props => [phoneNumber];
}

// OTP kodi tasdiqlandi
class OtpVerified extends AuthState {
  final String phoneNumber;

  const OtpVerified(this.phoneNumber);

  @override
  List<Object?> get props => [phoneNumber];
}

// Foydalanuvchi ro'yxatdan o'tdi
class AuthSuccess extends AuthState {
  final UserModel user;

  const AuthSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

// Xato holati
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
