import 'package:equatable/equatable.dart';

/// User model for API response
/// API format:
/// {
///   "name": "",
///   "surName": "",
///   "birthday": "0001-01-01T00:00:00",
///   "state": "",
///   "region": "",
///   "districts": "",
///   "telephoneNumber": "",
///   "address": "",
///   "token": "00000000-0000-0000-0000-000000000000"
/// }
class UserModel extends Equatable {
  final String name;
  final String surName;
  final String birthday;
  final String state;
  final String region;
  final String districts;
  final String telephoneNumber;
  final String address;
  final String token;

  const UserModel({
    required this.name,
    required this.surName,
    required this.birthday,
    required this.state,
    required this.region,
    required this.districts,
    required this.telephoneNumber,
    required this.address,
    required this.token,
  });

  /// Factory method to create from API JSON response
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'] as String? ?? '',
      surName: json['surName'] as String? ?? '',
      birthday: json['birthday'] as String? ?? '',
      state: json['state'] as String? ?? '',
      region: json['region'] as String? ?? '',
      districts: json['districts'] as String? ?? '',
      telephoneNumber: json['telephoneNumber'] as String? ?? '',
      address: json['address'] as String? ?? '',
      token: json['token'] as String? ?? '',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'name': name,
        'surName': surName,
        'birthday': birthday,
        'state': state,
        'region': region,
        'districts': districts,
        'telephoneNumber': telephoneNumber,
        'address': address,
        'token': token,
      };

  /// Full name getter
  String get fullName {
    if (name.isEmpty && surName.isEmpty) return '';
    return '$name $surName'.trim();
  }

  /// Copy with method
  UserModel copyWith({
    String? name,
    String? surName,
    String? birthday,
    String? state,
    String? region,
    String? districts,
    String? telephoneNumber,
    String? address,
    String? token,
  }) {
    return UserModel(
      name: name ?? this.name,
      surName: surName ?? this.surName,
      birthday: birthday ?? this.birthday,
      state: state ?? this.state,
      region: region ?? this.region,
      districts: districts ?? this.districts,
      telephoneNumber: telephoneNumber ?? this.telephoneNumber,
      address: address ?? this.address,
      token: token ?? this.token,
    );
  }

  @override
  List<Object?> get props => [
        name,
        surName,
        birthday,
        state,
        region,
        districts,
        telephoneNumber,
        address,
        token,
      ];

  @override
  String toString() {
    return 'UserModel(name: $name, surName: $surName, phone: $telephoneNumber, token: $token)';
  }
}
