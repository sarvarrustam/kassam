import 'package:equatable/equatable.dart';

enum TransactionType { income, expense }

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
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final DateTime date;
  final String? description;
  final String? notes;
  final String? paymentMethod;

  const Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.description,
    this.notes,
    this.paymentMethod,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    amount,
    type,
    category,
    date,
    description,
    notes,
    paymentMethod,
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
