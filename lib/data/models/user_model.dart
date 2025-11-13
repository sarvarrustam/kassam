import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String phoneNumber;

  const UserModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
  });

  @override
  List<Object> get props => [id, name, phoneNumber];

  // copyWith metodi
  UserModel copyWith({String? id, String? name, String? phoneNumber}) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}
