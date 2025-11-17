import 'package:flutter/material.dart';
import 'package:kassam/presentation/theme/app_colors.dart';
import 'package:kassam/data/models/transaction_model.dart';

class TransactionsListPage extends StatefulWidget {
  const TransactionsListPage({super.key});

  @override
  State<TransactionsListPage> createState() => _TransactionsListPageState();
}

class _TransactionsListPageState extends State<TransactionsListPage> {
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
  ];

  TransactionType? _filterType;
  TransactionCategory? _filterCategory;
  DateTime? _filterDate;

  List<Transaction> get _filteredTransactions {
    return _transactions.where((t) {
      if (_filterType != null && t.type != _filterType) return false;
      if (_filterCategory != null && t.category != _filterCategory)
        return false;
      if (_filterDate != null && t.date.year != _filterDate!.year ||
          t.date.month != _filterDate!.month) {
        return false;
      }
      return true;
    }).toList();
  }

  // Tranzaksiyalarni sanaga bo'lish
  Map<DateTime, List<Transaction>> _groupTransactionsByDate(
    List<Transaction> transactions,
  ) {
    final grouped = <DateTime, List<Transaction>>{};

    for (var transaction in transactions) {
      final key = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      grouped.putIfAbsent(key, () => []).add(transaction);
    }

    return grouped;
  }

  // Sana formati
  String _formatDate(DateTime date) {
    final today = DateTime.now();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return 'Bugun';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Kecha';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedTransactions = _groupTransactionsByDate(_filteredTransactions);
    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    double totalIncome = _filteredTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amount);

    double totalExpense = _filteredTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcha Tranzaksiyalar'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filtr',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('Hammasi'),
                            selected: _filterType == null,
                            onSelected: (selected) {
                              setState(() => _filterType = null);
                              Navigator.pop(context);
                            },
                          ),
                          FilterChip(
                            label: const Text('Kirim'),
                            selected: _filterType == TransactionType.income,
                            onSelected: (selected) {
                              setState(
                                () => _filterType = TransactionType.income,
                              );
                              Navigator.pop(context);
                            },
                          ),
                          FilterChip(
                            label: const Text('Chiqim'),
                            selected: _filterType == TransactionType.expense,
                            onSelected: (selected) {
                              setState(
                                () => _filterType = TransactionType.expense,
                              );
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _filterType = null;
                            _filterCategory = null;
                            _filterDate = null;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Filterni Ocharish'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Kirim va Chiqim Xulasasi
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey.shade100,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'Jami Kirim',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${totalIncome.toStringAsFixed(0)} UZS',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.successGreen,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 60,
                        color: Colors.grey.shade300,
                      ),
                      Column(
                        children: [
                          const Text(
                            'Jami Chiqim',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${totalExpense.toStringAsFixed(0)} UZS',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.errorRed,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(height: 1, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Net Balance: ',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        '${(totalIncome - totalExpense).toStringAsFixed(0)} UZS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: (totalIncome - totalExpense) >= 0
                              ? AppColors.successGreen
                              : AppColors.errorRed,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tranzaksiyalar ro'yxati
            if (sortedDates.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Hech qanday tranzaksiya yo\'q',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedDates.length,
                itemBuilder: (context, index) {
                  final date = sortedDates[index];
                  final dayTransactions = groupedTransactions[date]!;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            _formatDate(date),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        ...dayTransactions.map(
                          (transaction) =>
                              TransactionCard(transaction: transaction),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class TransactionCard extends StatelessWidget {
  final Transaction transaction;

  const TransactionCard({required this.transaction, super.key});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Color(
              int.parse('FF${transaction.getCategoryColor()}', radix: 16),
            ).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              transaction.getCategoryEmoji(),
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        title: Text(
          transaction.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          transaction.getCategoryName(),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isIncome ? '+' : '-'}${transaction.amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isIncome ? AppColors.successGreen : AppColors.errorRed,
              ),
            ),
            Text(
              '${transaction.date.hour}:${transaction.date.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
