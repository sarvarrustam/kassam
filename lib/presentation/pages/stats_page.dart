import 'package:flutter/material.dart';
import 'package:kassam/presentation/theme/app_colors.dart';
import 'package:kassam/data/services/mock_data_service.dart';
import 'package:kassam/data/models/transaction_model.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final _dataService = MockDataService();
  late int _selectedMonth;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
  }

  @override
  Widget build(BuildContext context) {
    final totalIncome = _dataService.getTotalIncome();
    final totalExpense = _dataService.getTotalExpense();
    final monthlyStats = _dataService.getMonthlyStats(
      _selectedMonth,
      _selectedYear,
    );
    final categoryTotals = _dataService.getCategoryTotals();
    final mostExpensive = _dataService.getMostExpensiveCategory();

    return Scaffold(
      appBar: AppBar(title: const Text('Statistika'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Jami Kirim/Chiqim
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jami Kirim',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${totalIncome.toStringAsFixed(0)} UZS',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.successGreen,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jami Xarajat',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${totalExpense.toStringAsFixed(0)} UZS',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.errorRed,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Oylik Statistika
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Oylik Statistika',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_selectedMonth/$_selectedYear',
                            style: TextStyle(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          label: 'Oylik Kirim',
                          amount: (monthlyStats['income'] ?? 0).toStringAsFixed(
                            0,
                          ),
                          color: AppColors.successGreen,
                          icon: Icons.arrow_downward,
                        ),
                        _StatItem(
                          label: 'Oylik Xarajat',
                          amount: (monthlyStats['expense'] ?? 0)
                              .toStringAsFixed(0),
                          color: AppColors.errorRed,
                          icon: Icons.arrow_upward,
                        ),
                        _StatItem(
                          label: 'Net Balans',
                          amount: (monthlyStats['balance'] ?? 0)
                              .toStringAsFixed(0),
                          color: (monthlyStats['balance'] ?? 0) >= 0
                              ? AppColors.successGreen
                              : AppColors.errorRed,
                          icon: Icons.account_balance,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // // Kategoriya Bo'yicha Analiz
            // Card(
            //   child: Padding(
            //     padding: const EdgeInsets.all(16),
            //     child: Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         Text(
            //           'Kategoriya Bo\'yicha',
            //           style: Theme.of(context).textTheme.titleMedium,
            //         ),
            //         const SizedBox(height: 16),
            //         if (categoryTotals.isEmpty)
            //           Center(
            //             child: Padding(
            //               padding: const EdgeInsets.symmetric(vertical: 20),
            //               child: Text(
            //                 'Hali Kategoriya Ma\'lumoti Yo\'q',
            //                 style: TextStyle(color: Colors.grey.shade600),
            //               ),
            //             ),
            //           )
            //         else
            //           Column(
            //             children: categoryTotals.entries.map((entry) {
            //               final total = entry.value;
            //               final percentage = (total / totalExpense * 100).clamp(0.0, 100.0);
            //               final transaction = Transaction(
            //                 id: '',
            //                 title: '',
            //                 amount: 0,
            //                 type: TransactionType.expense,
            //                 category: entry.key,
            //                 date: DateTime.now(),
            //               );

            //               return Padding(
            //                 padding: const EdgeInsets.only(bottom: 12),
            //                 child: Column(
            //                   crossAxisAlignment: CrossAxisAlignment.start,
            //                   children: [
            //                     Row(
            //                       children: [
            //                         Text(
            //                           transaction.getCategoryEmoji(),
            //                           style: const TextStyle(fontSize: 20),
            //                         ),
            //                         const SizedBox(width: 12),
            //                         Expanded(
            //                           child: Column(
            //                             crossAxisAlignment: CrossAxisAlignment.start,
            //                             children: [
            //                               Text(
            //                                 transaction.getCategoryName(),
            //                                 style: const TextStyle(
            //                                   fontWeight: FontWeight.w600,
            //                                   fontSize: 13,
            //                                 ),
            //                               ),
            //                               Text(
            //                                 '${percentage.toStringAsFixed(1)}%',
            //                                 style: TextStyle(
            //                                   fontSize: 11,
            //                                   color: Colors.grey.shade600,
            //                                 ),
            //                               ),
            //                             ],
            //                           ),
            //                         ),
            //                         Text(
            //                           '${total.toStringAsFixed(0)} UZS',
            //                           style: const TextStyle(
            //                             fontWeight: FontWeight.bold,
            //                             fontSize: 13,
            //                           ),
            //                         ),
            //                       ],
            //                     ),
            //                     const SizedBox(height: 8),
            //                     ClipRRect(
            //                       borderRadius: BorderRadius.circular(4),
            //                       child: LinearProgressIndicator(
            //                         value: percentage / 100,
            //                         minHeight: 6,
            //                         backgroundColor: Colors.grey.shade200,
            //                         valueColor: AlwaysStoppedAnimation(
            //                           Color(
            //                             int.parse(
            //                               'FF${transaction.getCategoryColor()}',
            //                               radix: 16,
            //                             ),
            //                           ),
            //                         ),
            //                       ),
            //                     ),
            //                   ],
            //                 ),
            //               );
            //             }).toList(),
            //           ),
            //       ],
            //     ),
            //   ),
            // ),
            // const SizedBox(height: 24),

            // Eng Ko'p Xarajat Kategoriyasi
            // if (mostExpensive != null)
            //   Card(
            //     color: Color(
            //       int.parse(
            //         'FF${Transaction(id: '', title: '', amount: 0, type: TransactionType.expense, category: mostExpensive, date: DateTime.now()).getCategoryColor()}',
            //         radix: 16,
            //       ),
            //     ).withValues(alpha: 0.1),
            //     child: Padding(
            //       padding: const EdgeInsets.all(16),
            //       child: Column(
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         children: [
            //           Text(
            //             'Eng Ko\'p Xarajat',
            //             style: Theme.of(context).textTheme.bodySmall?.copyWith(
            //               color: Colors.grey.shade600,
            //             ),
            //           ),
            //           const SizedBox(height: 12),
            //           Row(
            //             children: [
            //               Text(
            //                 Transaction(
            //                   id: '',
            //                   title: '',
            //                   amount: 0,
            //                   type: TransactionType.expense,
            //                   category: mostExpensive,
            //                   date: DateTime.now(),
            //                 ).getCategoryEmoji(),
            //                 style: const TextStyle(fontSize: 32),
            //               ),
            //               const SizedBox(width: 12),
            //               Column(
            //                 crossAxisAlignment: CrossAxisAlignment.start,
            //                 children: [
            //                   Text(
            //                     Transaction(
            //                       id: '',
            //                       title: '',
            //                       amount: 0,
            //                       type: TransactionType.expense,
            //                       category: mostExpensive,
            //                       date: DateTime.now(),
            //                     ).getCategoryName(),
            //                     style: const TextStyle(
            //                       fontWeight: FontWeight.bold,
            //                       fontSize: 16,
            //                     ),
            //                   ),
            //                   Text(
            //                     '${categoryTotals[mostExpensive]?.toStringAsFixed(0) ?? 0} UZS',
            //                     style: TextStyle(
            //                       color: Colors.grey.shade600,
            //                       fontSize: 12,
            //                     ),
            //                   ),
            //                 ],
            //               ),
            //             ],
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
