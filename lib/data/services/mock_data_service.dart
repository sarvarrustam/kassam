import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kassam/data/models/transaction_model.dart';
import 'package:kassam/data/models/wallet_model.dart';

/// Mock Data Service - Haqiqiy database integratsiyasigacha mock ma'lumot beradi
class MockDataService {
  static final MockDataService _instance = MockDataService._internal();

  MockDataService._internal();

  factory MockDataService() {
    return _instance;
  }

  static const String _walletsKey = 'wallets';
  static const String _transactionsKey = 'transactions';
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final walletsJson = prefs.getString(_walletsKey);
    final transactionsJson = prefs.getString(_transactionsKey);
    if (walletsJson != null) {
      final List decoded = jsonDecode(walletsJson);
      _wallets
        ..clear()
        ..addAll(decoded.map((e) => Wallet.fromJson(e)).toList());
    }
    if (transactionsJson != null) {
      final List decoded = jsonDecode(transactionsJson);
      _transactions
        ..clear()
        ..addAll(decoded.map((e) => Transaction.fromJson(e)).toList());
    }
    _initialized = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _walletsKey,
      jsonEncode(_wallets.map((w) => w.toJson()).toList()),
    );
    await prefs.setString(
      _transactionsKey,
      jsonEncode(_transactions.map((t) => t.toJson()).toList()),
    );
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
      walletId: '1',
    ),
    Transaction(
      id: '2',
      title: 'Bozorga sarf',
      amount: 250000,
      type: TransactionType.expense,
      category: TransactionCategory.grocery,
      date: DateTime.now().subtract(const Duration(days: 2)),
      notes: 'Weekly shopping',
      walletId: '1',
    ),
    Transaction(
      id: '3',
      title: 'Elektr tolovi',
      amount: 180000,
      type: TransactionType.expense,
      category: TransactionCategory.utilities,
      date: DateTime.now().subtract(const Duration(days: 1)),
      walletId: '2',
    ),
    Transaction(
      id: '4',
      title: 'Transport',
      amount: 80000,
      type: TransactionType.expense,
      category: TransactionCategory.transport,
      date: DateTime.now(),
      walletId: '1',
    ),
    Transaction(
      id: '5',
      title: 'Kino',
      amount: 60000,
      type: TransactionType.expense,
      category: TransactionCategory.entertainment,
      date: DateTime.now(),
      walletId: '3',
    ),
    Transaction(
      id: '6',
      title: 'Hadya',
      amount: 200000,
      type: TransactionType.income,
      category: TransactionCategory.gift,
      date: DateTime.now().subtract(const Duration(days: 3)),
      description: 'Birthday gift',
      walletId: '2',
    ),
  ];

  // Barcha transaksiyalarni olish
  List<Transaction> getTransactions() => List.from(_transactions);

  // Hamyon bo'yicha transaksiyalarni olish (agar walletId null bo'lsa barcha)
  List<Transaction> getTransactionsByWalletId(String? walletId) {
    if (walletId == null) return getTransactions();
    return _transactions.where((t) => t.walletId == walletId).toList();
  }

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
  Future<void> addTransaction(Transaction transaction) async {
    _transactions.add(transaction);
    final targetWalletId = transaction.walletId ?? getDefaultWallet()?.id;
    if (targetWalletId != null) {
      final wi = _wallets.indexWhere((w) => w.id == targetWalletId);
      if (wi != -1) {
        final w = _wallets[wi];
        final newBal = w.balance + transaction.signedAmount;
        _wallets[wi] = w.copyWith(balance: newBal);
      }
    }
    await _save();
  }

  // Tranzaksiyani o'chirish
  Future<void> deleteTransaction(String id) async {
    final idx = _transactions.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final t = _transactions.removeAt(idx);
      final targetWalletId = t.walletId ?? getDefaultWallet()?.id;
      if (targetWalletId != null) {
        final wi = _wallets.indexWhere((w) => w.id == targetWalletId);
        if (wi != -1) {
          final w = _wallets[wi];
          final newBal = w.balance - t.signedAmount;
          _wallets[wi] = w.copyWith(balance: newBal);
        }
      }
      await _save();
    }
  }

  // Update existing transaction
  Future<void> updateTransaction(String id, Transaction updated) async {
    final idx = _transactions.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final old = _transactions[idx];
    _transactions[idx] = updated;
    // handle wallet balances: remove old effect from old wallet, add new effect to new wallet
    final oldWalletId = old.walletId ?? getDefaultWallet()?.id;
    final newWalletId = updated.walletId ?? getDefaultWallet()?.id;

    if (oldWalletId != null) {
      final oi = _wallets.indexWhere((w) => w.id == oldWalletId);
      if (oi != -1) {
        final w = _wallets[oi];
        _wallets[oi] = w.copyWith(balance: w.balance - old.signedAmount);
      }
    }

    if (newWalletId != null) {
      final ni = _wallets.indexWhere((w) => w.id == newWalletId);
      if (ni != -1) {
        final w = _wallets[ni];
        _wallets[ni] = w.copyWith(balance: w.balance + updated.signedAmount);
      }
    }
    await _save();
  }

  // Hamyonni id orqali olish
  Wallet? getWalletById(String id) {
    try {
      return _wallets.firstWhere((w) => w.id == id);
    } catch (e) {
      return null;
    }
  }

  // Yangi hamyon qo'shish
  Future<Wallet> addWallet(String name) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final wallet = Wallet(
      id: id,
      name: name,
      type: WalletType.checking,
      balance: 0,
      currency: 'UZS',
      color: '9E9E9E',
      createdAt: DateTime.now(),
    );
    _wallets.add(wallet);
    await _save();
    return wallet;
  }

  // Hamyonni o'chirish (va unga bog'langan transaksiyalarni ham o'chirish)
  Future<void> deleteWallet(String id) async {
    _wallets.removeWhere((w) => w.id == id);
    _transactions.removeWhere((t) => t.walletId == id);
    await _save();
  }

  // Set given wallet as default (mark isDefault)
  Future<void> setDefaultWallet(String id) async {
    for (var i = 0; i < _wallets.length; i++) {
      final w = _wallets[i];
      _wallets[i] = w.copyWith(isDefault: w.id == id);
    }
    await _save();
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
