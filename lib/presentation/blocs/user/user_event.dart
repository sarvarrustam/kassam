part of 'user_bloc.dart';

class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object> get props => [];
}

class UserGetDataEvent extends UserEvent {}

class UserSaveDataEvent extends UserEvent {
  final UserModel user;
  const UserSaveDataEvent(this.user);

  @override
  List<Object> get props => [user];
}

class UserClearDataEvent extends UserEvent {}
