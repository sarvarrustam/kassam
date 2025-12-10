import 'package:equatable/equatable.dart';

/// Wallet balance model for API response
/// API format:
/// {
///   "name": "som kassam",
///   "id": "94ec7d57-e3be-4bf7-b1dd-2711383945a6",
///   "type": "uzs",
///   "value": 700000
/// }
class WalletBalance extends Equatable {
  final String id;
  final String name;
  final String type; // "uzs" or "usd"
  final double value;

  const WalletBalance({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
  });

  /// Factory method to create from API JSON response
  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      value: (json['value'] as num).toDouble(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'value': value,
      };

  /// Get currency code (UZS or USD)
  String get currency {
    return type == 'usd' ? 'USD' : 'UZS';
  }

  /// Copy with method for updating fields
  WalletBalance copyWith({
    String? id,
    String? name,
    String? type,
    double? value,
  }) {
    return WalletBalance(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      value: value ?? this.value,
    );
  }

  @override
  List<Object?> get props => [id, name, type, value];

  @override
  String toString() {
    return 'WalletBalance(id: $id, name: $name, type: $type, value: $value, currency: $currency)';
  }
}
