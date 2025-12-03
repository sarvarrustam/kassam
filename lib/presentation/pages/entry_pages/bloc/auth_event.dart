part of 'auth_bloc.dart';

 class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

final class AuthRequestedSmsCode extends AuthEvent {
  final String phoneNumber;

  const AuthRequestedSmsCode(this.phoneNumber);

  @override
  List<Object> get props => [phoneNumber];
}

final class AuthVerifySmsCode extends AuthEvent {
  final String phoneNumber;
  final String smsCode;

  const AuthVerifySmsCode(this.phoneNumber, this.smsCode);

  @override
  List<Object> get props => [phoneNumber, smsCode];
}

final class AuthCreateProfile extends AuthEvent {
  final String name;
  final String surname;
  final String birthday;
  final String address;
  final String? stateId;
  final String? regionId;
  final String? districtsId;

  const AuthCreateProfile({
    required this.name,
    required this.surname,
    required this.birthday,
    required this.address,
    this.stateId,
    this.regionId,
    this.districtsId,
  });

  @override
  List<Object> get props => [
    name, 
    surname, 
    birthday, 
    address, 
    if (stateId != null) stateId!, 
    if (regionId != null) regionId!, 
    if (districtsId != null) districtsId!
  ];
}


