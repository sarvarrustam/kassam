part of 'auth_bloc.dart';

 class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object> get props => [];
}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

final class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}

final class AuthSmsCodeSent extends AuthState {}

// SMS verified - user bazada BOR (home page)
final class AuthVerifiedUserExists extends AuthState {}

// SMS verified - user bazada YO'Q (registration page)
final class AuthVerifiedUserNew extends AuthState {}

// Profile created successfully
final class AuthProfileCreated extends AuthState {}

