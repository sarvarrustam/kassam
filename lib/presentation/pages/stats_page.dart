import 'package:flutter/material.dart';
// import 'package:kassam/presentation/theme/app_colors.dart';
import 'package:kassam/data/services/mock_data_service.dart';
import 'package:kassam/data/models/transaction_model.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final _dataService = MockDataService();
  // month/year selection removed for simplified stats view
  String? _selectedWalletId;

  void _showAddTransactionSheet() {
    // Centered dialog instead of bottom sheet
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        TransactionType type = TransactionType.expense;
        final titleCtrl = TextEditingController();
        final amountCtrl = TextEditingController();

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StatefulBuilder(
                builder: (context, setStateSB) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Yangi Tranzaksiya',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogCtx).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Chiqim'),
                            selected: type == TransactionType.expense,
                            selectedColor: Colors.redAccent,
                            backgroundColor: Colors.grey[200],
                            labelStyle: TextStyle(
                              color: type == TransactionType.expense
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                            onSelected: (v) => setStateSB(
                              () => type = TransactionType.expense,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Kirim'),
                            selected: type == TransactionType.income,
                            selectedColor: Colors.green,
                            backgroundColor: Colors.grey[200],
                            labelStyle: TextStyle(
                              color: type == TransactionType.income
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                            onSelected: (v) =>
                                setStateSB(() => type = TransactionType.income),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Sarlavha',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: amountCtrl,
                        decoration: const InputDecoration(labelText: 'Summа'),
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogCtx).pop(),
                            child: const Text('Bekor qilish'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              final title = titleCtrl.text.trim().isEmpty
                                  ? (type == TransactionType.income
                                        ? 'Kirim'
                                        : 'Chiqim')
                                  : titleCtrl.text.trim();
                              final amount =
                                  double.tryParse(
                                    amountCtrl.text.replaceAll(',', '.'),
                                  ) ??
                                  0.0;
                              if (amount <= 0) return;

                              final id = DateTime.now().millisecondsSinceEpoch
                                  .toString();
                              final category = type == TransactionType.income
                                  ? TransactionCategory.salary
                                  : TransactionCategory.grocery;
                              final transaction = Transaction(
                                id: id,
                                title: title,
                                amount: amount,
                                type: type,
                                category: category,
                                date: DateTime.now(),
                                walletId: _selectedWalletId,
                              );
                              () async {
                                await _dataService.addTransaction(transaction);
                                setState(() {});
                                Navigator.of(dialogCtx).pop();
                              }();
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditTransactionSheet(Transaction t) {
    // Centered dialog for edit
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        TransactionType type = t.type;
        final titleCtrl = TextEditingController(text: t.title);
        final amountCtrl = TextEditingController(text: t.amount.toString());

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StatefulBuilder(
                builder: (context, setStateSB) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tranzaksiyani Tahrirlash',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogCtx).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Chiqim'),
                            selected: type == TransactionType.expense,
                            selectedColor: Colors.redAccent,
                            backgroundColor: Colors.grey[200],
                            labelStyle: TextStyle(
                              color: type == TransactionType.expense
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                            onSelected: (v) => setStateSB(
                              () => type = TransactionType.expense,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Kirim'),
                            selected: type == TransactionType.income,
                            selectedColor: Colors.green,
                            backgroundColor: Colors.grey[200],
                            labelStyle: TextStyle(
                              color: type == TransactionType.income
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                            onSelected: (v) =>
                                setStateSB(() => type = TransactionType.income),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Sarlavha',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: amountCtrl,
                        decoration: const InputDecoration(labelText: 'Summа'),
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogCtx).pop(),
                            child: const Text('Bekor qilish'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              final title = titleCtrl.text.trim().isEmpty
                                  ? (type == TransactionType.income
                                        ? 'Kirim'
                                        : 'Chiqim')
                                  : titleCtrl.text.trim();
                              final amount =
                                  double.tryParse(
                                    amountCtrl.text.replaceAll(',', '.'),
                                  ) ??
                                  0.0;
                              if (amount <= 0) return;

                              final updated = Transaction(
                                id: t.id,
                                title: title,
                                amount: amount,
                                type: type,
                                category: type == TransactionType.income
                                    ? TransactionCategory.salary
                                    : TransactionCategory.grocery,
                                date: DateTime.now(),
                                walletId: t.walletId ?? _selectedWalletId,
                              );
                              () async {
                                await _dataService.updateTransaction(
                                  t.id,
                                  updated,
                                );
                                setState(() {});
                                Navigator.of(dialogCtx).pop();
                              }();
                            },
                            child: const Text('Saqlash'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showWalletsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        final wallets = _dataService.getWallets();
        final nameCtrl = TextEditingController();

        return StatefulBuilder(
          builder: (context, setStateSB) {
            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          ...wallets.map((w) {
                            final selected = w.id == _selectedWalletId;
                            return ListTile(
                              leading: const Icon(
                                Icons.account_balance_wallet_outlined,
                              ),
                              title: Text(w.name),
                              subtitle: Text(
                                '${w.balance.toStringAsFixed(0)} so\'m',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (selected)
                                    const Icon(Icons.check, color: Colors.green)
                                  else
                                    const SizedBox.shrink(),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (dctx) {
                                          return AlertDialog(
                                            title: const Text(
                                              'Hamyonni o\'chirish',
                                            ),
                                            content: const Text(
                                              'Siz haqiqatan ham bu hamyonni o\'chirmoqchisiz?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(dctx).pop(),
                                                child: const Text(
                                                  'Bekor qilish',
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  await _dataService
                                                      .deleteWallet(w.id);
                                                  setState(() {});
                                                  setStateSB(() {});
                                                  Navigator.of(dctx).pop();
                                                },
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    child: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedWalletId = w.id;
                                });
                                Navigator.of(ctx).pop();
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (dctx) {
                          return Dialog(
                            insetAnimationDuration: const Duration(
                              milliseconds: 300,
                            ),
                            insetAnimationCurve: Curves.easeOut,
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Yangi Hamyon qo\'shish',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: nameCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Hamyon nomi',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(dctx).pop(),
                                          child: const Text('Bekor qilish'),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () {
                                            final name = nameCtrl.text.trim();
                                            if (name.isEmpty) return;
                                            _dataService.addWallet(name).then((
                                              newWallet,
                                            ) {
                                              setState(() {
                                                _selectedWalletId =
                                                    newWallet.id;
                                              });
                                              Navigator.of(dctx).pop();
                                              Navigator.of(ctx).pop();
                                              setState(() {});
                                            });
                                          },
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: const Text("Yangi Hamyon qo'shish"),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedWalletId = _dataService.getDefaultWallet()?.id;
  }

  @override
  Widget build(BuildContext context) {
    // simplified stats view uses wallet balance and recent transactions

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _dataService.getWalletById(_selectedWalletId ?? '')?.name ?? 'Hamyon',
        ),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showWalletsSheet,
            icon: const Icon(Icons.account_balance_wallet_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          // Umumiy Hisob - fixed tepada
          SingleChildScrollView(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromARGB(255, 61, 212, 149),
                    Color.fromARGB(255, 61, 212, 149),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _dataService.getWalletById(_selectedWalletId ?? '')?.name ??
                        'Umumiy Hisob',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${(_dataService.getWalletById(_selectedWalletId ?? '')?.balance ?? _dataService.getNetBalance()).toStringAsFixed(0)} so\'m',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Icon(
                    Icons.insert_chart_outlined,
                    color: Colors.white.withOpacity(0.9),
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Xisobot',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          // Scrollable tranzaksiyalar ro'yxati
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: () {
                      final transactions = _dataService
                          .getTransactionsByWalletId(_selectedWalletId);
                      final sorted = List<Transaction>.from(transactions)
                        ..sort((a, b) => b.date.compareTo(a.date));
                      return sorted.map((t) {
                        final isExpense = t.type == TransactionType.expense;
                        final bgGradient = isExpense
                            ? const LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 209, 105, 103),
                                  Color(0xFFE53935),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : const LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 61, 212, 149),
                                  Color.fromARGB(255, 61, 212, 149),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            gradient: bgGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Sana: ${t.date.day.toString().padLeft(2, '0')}.${t.date.month.toString().padLeft(2, '0')}.${t.date.year} ${t.date.hour.toString().padLeft(2, '0')}:${t.date.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    if (t.type == TransactionType.income)
                                      const SizedBox(height: 4),
                                    if (t.type == TransactionType.income)
                                      Text(
                                        'Hamyon: ${t.category.name}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${t.amount.toStringAsFixed(0)} so\'m',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () =>
                                            _showEditTransactionSheet(t),
                                        child: const Icon(
                                          Icons.edit,
                                          color: Colors.white70,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () async {
                                          await _dataService.deleteTransaction(
                                            t.id,
                                          );
                                          setState(() {});
                                        },
                                        child: const Icon(
                                          Icons.delete,
                                          color: Colors.white70,
                                          size: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList();
                    }(),
                  ),

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
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionSheet,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// _StatItem removed — simplified stats page does not use small stat items
