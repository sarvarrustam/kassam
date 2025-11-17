import 'package:kassam/data/models/transaction_model.dart';
import 'package:kassam/data/models/wallet_model.dart';

/// Mock Data Service - Haqiqiy database integratsiyasigacha mock ma'lumot beradi
class MockDataService {
  static final MockDataService _instance = MockDataService._internal();

  MockDataService._internal();

  factory MockDataService() {
    return _instance;
  }

  // Mock Wallets
  final List<Wallet> _wallets = [
    Wallet(
      id: '1',
      name: 'Asosiy Hisob',
      type: WalletType.checking,
      balance: 3500000,
      currency: 'UZS',
      color: '388E3C',
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      isDefault: true,
    ),
    Wallet(
      id: '2',
      name: 'Jamg\'al',
      type: WalletType.savings,
      balance: 8500000,
      currency: 'UZS',
      color: '2196F3',
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
    ),
    Wallet(
      id: '3',
      name: 'Visa Card',
      type: WalletType.card,
      balance: 1200000,
      currency: 'UZS',
      color: 'FF9800',
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
  ];

  // Mock Transactions
  final List<Transaction> _transactions = [
    Transaction(
      id: '1',
      title: 'Oylik Maosh',
      amount: 5000000,
      type: TransactionType.income,
      category: TransactionCategory.salary,
      date: DateTime.now().subtract(const Duration(days: 5)),
      description: 'Company salary',
    ),
    Transaction(
      id: '2',
      title: 'Bozorga sarf',
      amount: 250000,
      type: TransactionType.expense,
      category: TransactionCategory.grocery,
      date: DateTime.now().subtract(const Duration(days: 2)),
      notes: 'Weekly shopping',
    ),
    Transaction(
      id: '3',
      title: 'Elektr tolovi',
      amount: 180000,
      type: TransactionType.expense,
      category: TransactionCategory.utilities,
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Transaction(
      id: '4',
      title: 'Transport',
      amount: 80000,
      type: TransactionType.expense,
      category: TransactionCategory.transport,
      date: DateTime.now(),
    ),
    Transaction(
      id: '5',
      title: 'Kino',
      amount: 60000,
      type: TransactionType.expense,
      category: TransactionCategory.entertainment,
      date: DateTime.now(),
    ),
    Transaction(
      id: '6',
      title: 'Hadya',
      amount: 200000,
      type: TransactionType.income,
      category: TransactionCategory.gift,
      date: DateTime.now().subtract(const Duration(days: 3)),
      description: 'Birthday gift',
    ),
  ];

  // Barcha transaksiyalarni olish
  List<Transaction> getTransactions() => List.from(_transactions);

  // Kategoriya bo'yicha transaksiyalarni olish
  List<Transaction> getTransactionsByCategory(TransactionCategory category) {
    return _transactions.where((t) => t.category == category).toList();
  }

  // Tur bo'yicha transaksiyalarni olish (kirim/chiqim)
  List<Transaction> getTransactionsByType(TransactionType type) {
    return _transactions.where((t) => t.type == type).toList();
  }

  // Sana bo'yicha transaksiyalarni olish
  List<Transaction> getTransactionsByDate(DateTime date) {
    return _transactions
        .where(
          (t) =>
              t.date.year == date.year &&
              t.date.month == date.month &&
              t.date.day == date.day,
        )
        .toList();
  }

  // Oylik transaksiyalarni olish
  List<Transaction> getTransactionsByMonth(int month, int year) {
    return _transactions
        .where((t) => t.date.month == month && t.date.year == year)
        .toList();
  }

  // Yangi transaksiya qo'shish
  void addTransaction(Transaction transaction) {
    _transactions.add(transaction);
  }

  // Tranzaksiyani o'chirish
  void deleteTransaction(String id) {
    _transactions.removeWhere((t) => t.id == id);
  }

  // Jami kirim
  double getTotalIncome() {
    return _transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amount);
  }

  // Jami chiqim
  double getTotalExpense() {
    return _transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amount);
  }

  // Net balans
  double getNetBalance() => getTotalIncome() - getTotalExpense();

  // Kategoriya bo'yicha xulasa
  Map<TransactionCategory, double> getCategoryTotals() {
    final totals = <TransactionCategory, double>{};
    for (final transaction in _transactions) {
      totals[transaction.category] =
          (totals[transaction.category] ?? 0) + transaction.amount;
    }
    return totals;
  }

  // Hamyonlarni olish
  List<Wallet> getWallets() => List.from(_wallets);

  // Default hamyonni olish
  Wallet? getDefaultWallet() {
    try {
      return _wallets.firstWhere((w) => w.isDefault);
    } catch (e) {
      return null;
    }
  }

  // Jami hamyon balansa
  double getTotalWalletBalance() {
    return _wallets.fold(0, (sum, w) => sum + w.balance);
  }

  // O'tgan oyning kirim/chiqimi
  Map<String, double> getMonthlyStats(int month, int year) {
    final monthTransactions = getTransactionsByMonth(month, year);
    final income = monthTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final expense = monthTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    return {'income': income, 'expense': expense, 'balance': income - expense};
  }

  // Eng ko'p xarajat kategoriyasi
  TransactionCategory? getMostExpensiveCategory() {
    final categoryTotals = getCategoryTotals();
    if (categoryTotals.isEmpty) return null;

    TransactionCategory? mostExpensive;
    double maxAmount = 0;

    categoryTotals.forEach((category, amount) {
      if (amount > maxAmount) {
        maxAmount = amount;
        mostExpensive = category;
      }
    });

    return mostExpensive;
  }

  // Xarajat limitini tekshirish
  bool isExpenseOverBudget(double budget, int month, int year) {
    final expense = getMonthlyStats(month, year)['expense'] ?? 0;
    return expense > budget;
  }
}
