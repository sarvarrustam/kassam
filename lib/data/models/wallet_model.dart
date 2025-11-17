import 'package:equatable/equatable.dart';

enum WalletType { checking, savings, cash, card }

class Wallet extends Equatable {
  final String id;
  final String name;
  final WalletType type;
  final double balance;
  final String currency;
  final String color;
  final DateTime createdAt;
  final bool isDefault;

  const Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.currency,
    required this.color,
    required this.createdAt,
    this.isDefault = false,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    balance,
    currency,
    color,
    createdAt,
    isDefault,
  ];

  // Wallet turi nomi
  String getTypeName() {
    switch (type) {
      case WalletType.checking:
        return 'Tekshirish Hisobi';
      case WalletType.savings:
        return 'Jamg\'al Hisobi';
      case WalletType.cash:
        return 'Naqd Pul';
      case WalletType.card:
        return 'Plastik Karta';
    }
  }

  // Wallet turi ikoni
  String getTypeIcon() {
    switch (type) {
      case WalletType.checking:
        return '🏦';
      case WalletType.savings:
        return '🏧';
      case WalletType.cash:
        return '💵';
      case WalletType.card:
        return '💳';
    }
  }

  // Wallet ko'chi chiqarish
  Wallet copyWith({
    String? id,
    String? name,
    WalletType? type,
    double? balance,
    String? currency,
    String? color,
    DateTime? createdAt,
    bool? isDefault,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
