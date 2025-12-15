import 'package:equatable/equatable.dart';

enum TransactionType { 
  income,      // Kirim
  expense,     // Chiqim
  loanTaken,   // Qarz olish
  loanGiven,   // Qarz berish
}

enum TransactionCategory {
  salary,
  gift,
  investment,
  loan,
  grocery,
  restaurant,
  transport,
  utilities,
  entertainment,
  healthcare,
  shopping,
  education,
  subscription,
  other,
}

class Transaction extends Equatable {
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values[json['type'] as int],
      category: TransactionCategory.values[json['category'] as int],
      date: DateTime.parse(json['date'] as String),
      walletId: json['walletId'] as String?,
      description: json['description'] as String?,
      notes: json['notes'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      customCategoryName: json['customCategoryName'] as String?,
      customCategoryEmoji: json['customCategoryEmoji'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'type': type.index,
    'category': category.index,
    'date': date.toIso8601String(),
    'walletId': walletId,
    'description': description,
    'notes': notes,
    'paymentMethod': paymentMethod,
    'customCategoryName': customCategoryName,
    'customCategoryEmoji': customCategoryEmoji,
  };
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final DateTime date;
  final String? walletId;
  final String? description;
  final String? notes;
  final String? paymentMethod;
  final String? customCategoryName;
  final String? customCategoryEmoji;

  const Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.walletId,
    this.description,
    this.notes,
    this.paymentMethod,
    this.customCategoryName,
    this.customCategoryEmoji,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    amount,
    type,
    category,
    date,
    walletId,
    description,
    notes,
    paymentMethod,
    customCategoryName,
    customCategoryEmoji,
  ];

  // Kirim yoki chiqimni aniqlash
  double get signedAmount => type == TransactionType.income ? amount : -amount;

  // Kategoriya rangi
  String getCategoryColor() {
    switch (category) {
      case TransactionCategory.salary:
      case TransactionCategory.gift:
      case TransactionCategory.investment:
        return '388E3C'; // Green - Income
      case TransactionCategory.grocery:
      case TransactionCategory.restaurant:
        return 'FF9800'; // Orange - Food
      case TransactionCategory.transport:
        return '2196F3'; // Blue - Transport
      case TransactionCategory.utilities:
      case TransactionCategory.subscription:
        return '9C27B0'; // Purple - Bills
      case TransactionCategory.entertainment:
        return 'E91E63'; // Pink - Fun
      case TransactionCategory.healthcare:
        return 'F44336'; // Red - Health
      case TransactionCategory.shopping:
        return 'FF5722'; // Deep Orange - Shopping
      case TransactionCategory.education:
        return '673AB7'; // Deep Purple - Education
      case TransactionCategory.loan:
        return '607D8B'; // Blue Grey - Loan
      default:
        return '757575'; // Grey - Other
    }
  }

  // Kategoriya nomi (Uzbek)
  String getCategoryName() {
    // If category is 'other' but a custom name was provided, return it
    if (category == TransactionCategory.other &&
        customCategoryName != null &&
        customCategoryName!.isNotEmpty) {
      return customCategoryName!;
    }

    switch (category) {
      case TransactionCategory.salary:
        return 'Oylik Maosh';
      case TransactionCategory.gift:
        return 'Hadya';
      case TransactionCategory.investment:
        return 'Investitsiya';
      case TransactionCategory.loan:
        return 'Kredit';
      case TransactionCategory.grocery:
        return 'Oziq-Ovqat';
      case TransactionCategory.restaurant:
        return 'Restoran';
      case TransactionCategory.transport:
        return 'Transport';
      case TransactionCategory.utilities:
        return 'Kommunal';
      case TransactionCategory.entertainment:
        return 'O\'yin-Kulgili';
      case TransactionCategory.healthcare:
        return 'Sog\'liq';
      case TransactionCategory.shopping:
        return 'Xarid';
      case TransactionCategory.education:
        return 'Ta\'lim';
      case TransactionCategory.subscription:
        return 'Obuna';
      case TransactionCategory.other:
        return 'Boshqa';
    }
  }

  // Kategoriya emoji
  String getCategoryEmoji() {
    // If category is 'other' but a custom emoji was provided, return it
    if (category == TransactionCategory.other &&
        customCategoryEmoji != null &&
        customCategoryEmoji!.isNotEmpty) {
      return customCategoryEmoji!;
    }

    switch (category) {
      case TransactionCategory.salary:
        return '💼';
      case TransactionCategory.gift:
        return '🎁';
      case TransactionCategory.investment:
        return '📈';
      case TransactionCategory.loan:
        return '💳';
      case TransactionCategory.grocery:
        return '🛒';
      case TransactionCategory.restaurant:
        return '🍽️';
      case TransactionCategory.transport:
        return '🚕';
      case TransactionCategory.utilities:
        return '💡';
      case TransactionCategory.entertainment:
        return '🎬';
      case TransactionCategory.healthcare:
        return '⚕️';
      case TransactionCategory.shopping:
        return '👗';
      case TransactionCategory.education:
        return '📚';
      case TransactionCategory.subscription:
        return '📱';
      case TransactionCategory.other:
        return '📝';
    }
  }
}
