import 'package:flutter/material.dart';
import 'package:kassam/presentation/theme/app_colors.dart';
import 'package:kassam/data/services/mock_data_service.dart';
import 'package:kassam/data/models/transaction_model.dart';

class StatsPage extends StatefulWidget {
  final String? walletId;

  const StatsPage({super.key, this.walletId});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final _dataService = MockDataService();
  // month/year selection removed for simplified stats view
  String? _selectedWalletId;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  bool _showBalance = true; // Balance visibility toggle

  @override
  void initState() {
    super.initState();
    // Set selected wallet from route parameter
    if (widget.walletId != null) {
      _selectedWalletId = widget.walletId;
    }
  }

  void _showDateRangePickerDialog() {
    showDialog(
      context: context,
      builder: (context) {
        DateTime tempStartDate =
            _filterStartDate ??
            DateTime.now().subtract(const Duration(days: 30));
        DateTime tempEndDate = _filterEndDate ?? DateTime.now();

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Sana oralığini tanlang'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Boshlanish sanasi
                  ListTile(
                    title: const Text('Boshlanish sanasi'),
                    subtitle: Text(
                      '${tempStartDate.day.toString().padLeft(2, '0')}.${tempStartDate.month.toString().padLeft(2, '0')}.${tempStartDate.year}',
                    ),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: tempStartDate,
                        firstDate: DateTime(2020),
                        lastDate: tempEndDate,
                      );
                      if (pickedDate != null) {
                        setStateDialog(() {
                          tempStartDate = pickedDate;
                        });
                      }
                    },
                  ),
                  const Divider(),
                  // Tugallash sanasi
                  ListTile(
                    title: const Text('Tugallash sanasi'),
                    subtitle: Text(
                      '${tempEndDate.day.toString().padLeft(2, '0')}.${tempEndDate.month.toString().padLeft(2, '0')}.${tempEndDate.year}',
                    ),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: tempEndDate,
                        firstDate: tempStartDate,
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        setStateDialog(() {
                          tempEndDate = pickedDate;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filterStartDate = null;
                      _filterEndDate = null;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Tozalash'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Bekor qilish'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filterStartDate = tempStartDate;
                      _filterEndDate = tempEndDate;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Qo\'llash'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddTransactionSheet() {
    // Main dialog for transaction
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        TransactionType type = TransactionType.expense;
        TransactionCategory? selectedCategory;
        final titleCtrl = TextEditingController();
        final amountCtrl = TextEditingController();

        return StatefulBuilder(
          builder: (context, setStateSB) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
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
                      // Chiqim/Kirim tanlash
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
                            onSelected: (v) {
                              setStateSB(() {
                                type = TransactionType.expense;
                                selectedCategory = null;
                              });
                            },
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
                            onSelected: (v) {
                              setStateSB(() {
                                type = TransactionType.income;
                                selectedCategory = null;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Summa kiritish
                      TextField(
                        controller: amountCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Summa',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (value) {
                          final clean = value.replaceAll(' ', '');
                          if (clean.isEmpty) return;
                          try {
                            final parts = clean.split('.');
                            final intPart = int.parse(parts[0]);
                            final formatted = _formatNumber(intPart);
                            final decimal = parts.length > 1
                                ? '.${parts[1]}'
                                : '';
                            final newText = formatted + decimal;

                            if (amountCtrl.text != newText) {
                              amountCtrl.value = TextEditingValue(
                                text: newText,
                                selection: TextSelection.collapsed(
                                  offset: newText.length,
                                ),
                              );
                            }
                          } catch (e) {
                            // Invalid format
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      // Chiqim/Kirim turi tugmasi
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                          ),
                          onPressed: () {
                            // Bottom sheet ochish kategoriya tanlash uchun
                            _showCategorySelectionSheet(type, (selectedCat) {
                              setStateSB(() {
                                selectedCategory = selectedCat;
                                titleCtrl.text = _getCategoryName(selectedCat);
                              });
                            });
                          },
                          child: Text(
                            selectedCategory != null
                                ? _getCategoryName(selectedCategory!)
                                : (type == TransactionType.income
                                      ? 'Kirim turi tanlang'
                                      : 'Chiqim turi tanlang'),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Sarlavha kiritish
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Sarlavha',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // OK va Bekor qilish tugmalari
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
                              if (_selectedWalletId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Avval hamyon tanlang!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }

                              final title = titleCtrl.text.trim().isEmpty
                                  ? (type == TransactionType.income
                                        ? 'Kirim'
                                        : 'Chiqim')
                                  : titleCtrl.text.trim();
                              final amount =
                                  double.tryParse(
                                    amountCtrl.text
                                        .replaceAll(' ', '')
                                        .replaceAll(',', '.'),
                                  ) ??
                                  0.0;
                              if (amount <= 0) return;

                              final id = DateTime.now().millisecondsSinceEpoch
                                  .toString();
                              final category =
                                  selectedCategory ??
                                  (type == TransactionType.income
                                      ? TransactionCategory.salary
                                      : TransactionCategory.grocery);
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
                                if (mounted) {
                                  setState(() {});
                                  Navigator.of(dialogCtx).pop();
                                }
                              }();
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
    );
  }

  void _showCategorySelectionSheet(
    TransactionType type,
    Function(TransactionCategory) onSelected,
  ) {
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            final allCategories = _getCategories(type);
            final categories = searchQuery.isEmpty
                ? allCategories
                : allCategories
                      .where(
                        (cat) => _getCategoryName(
                          cat,
                        ).toLowerCase().contains(searchQuery.toLowerCase()),
                      )
                      .toList();

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      type == TransactionType.income
                          ? 'Kirim turi tanlang'
                          : 'Chiqim turi tanlang',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Search qismi
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Kategoriasini izlash...',
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setStateSB(() {
                          searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Kategoriyalar ro'yxati
                    if (categories.isEmpty)
                      Center(
                        child: Text(
                          'Kategoriya topilmadi',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: categories.length,
                        itemBuilder: (ctx, index) {
                          final cat = categories[index];
                          return ListTile(
                            leading: Icon(_getCategoryIcon(cat)),
                            title: Text(_getCategoryName(cat)),
                            onTap: () {
                              onSelected(cat);
                              Navigator.of(sheetCtx).pop();
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            );
          },
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
                              title: Text('${w.currency} - ${w.name}'),
                              subtitle: Text(
                                '${_formatNumber(w.balance.toInt())} ${w.currency == 'UZS' ? 'so\'m' : '\$'}',
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
                                                  setState(() {
                                                    _selectedWalletId = null;
                                                  });
                                                  Navigator.of(dctx).pop();
                                                  Navigator.of(ctx).pop();
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
                            alignment: Alignment.center,
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
                                    DefaultTabController(
                                      length: 2,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TabBar(
                                            tabs: const [
                                              Tab(text: 'UZS'),
                                              Tab(text: 'USD'),
                                            ],
                                            labelColor: Colors.green,
                                            unselectedLabelColor: Colors.grey,
                                            indicatorColor: Colors.green,
                                          ),
                                          const SizedBox(height: 16),
                                          SizedBox(
                                            height: 160,
                                            child: TabBarView(
                                              children: [
                                                // UZS Tab
                                                _buildWalletInputTab(
                                                  'so\'m',
                                                  'UZS',
                                                  (name) {
                                                    if (name.isEmpty) return;
                                                    _dataService
                                                        .addWallet(
                                                          name,
                                                          currency: 'UZS',
                                                        )
                                                        .then((newWallet) {
                                                          setState(() {
                                                            _selectedWalletId =
                                                                newWallet.id;
                                                          });
                                                          Navigator.of(
                                                            dctx,
                                                          ).pop();
                                                          Navigator.of(
                                                            ctx,
                                                          ).pop();
                                                          setState(() {});
                                                        });
                                                  },
                                                ),
                                                // USD Tab
                                                _buildWalletInputTab(
                                                  '\$',
                                                  'USD',
                                                  (name) {
                                                    if (name.isEmpty) return;
                                                    _dataService
                                                        .addWallet(
                                                          name,
                                                          currency: 'USD',
                                                        )
                                                        .then((newWallet) {
                                                          setState(() {
                                                            _selectedWalletId =
                                                                newWallet.id;
                                                          });
                                                          Navigator.of(
                                                            dctx,
                                                          ).pop();
                                                          Navigator.of(
                                                            ctx,
                                                          ).pop();
                                                          setState(() {});
                                                        });
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
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
  Widget build(BuildContext context) {
    // simplified stats view uses wallet balance and recent transactions

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _dataService.getWalletById(_selectedWalletId ?? '')?.name ?? 'Hamyon',
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryGreen, AppColors.primaryGreenLight],
            ),
          ),
        ),
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryGreen, AppColors.primaryGreenLight],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      Center(
                        child: Text(
                          _dataService
                                  .getWalletById(_selectedWalletId ?? '')
                                  ?.name ??
                              'Umumiy Hisob',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                        ),
                      ),
                      IconButton(
                        onPressed: _showDateRangePickerDialog,
                        icon: Icon(
                          Icons.filter_list,
                          color: Colors.white.withOpacity(0.9),
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Jami suma with eye icon toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 36), // Space for icon alignment
                      Expanded(
                        child: Text(
                          _showBalance
                              ? '${_formatNumber((_dataService.getWalletById(_selectedWalletId ?? '')?.balance ?? _dataService.getNetBalance()).toInt())} ${_dataService.getWalletById(_selectedWalletId ?? '')?.currency == 'USD' ? '\$' : 'so\'m'}'
                              : '••••••',
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showBalance = !_showBalance;
                          });
                        },
                        child: Icon(
                          _showBalance
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white.withOpacity(0.7),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Chiqim va Kirim statistikasi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Chap: Chiqim (Qizil)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chiqim',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.white, fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_formatNumber(_calculateExpenseTotal().toInt())} ${_getCurrencySymbol()}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.red.shade300,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      // Markaziy: Xisobot icon
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.insert_chart_outlined,
                            color: Colors.white.withOpacity(0.7),
                            size: 22,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Xisobot',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.white70, fontSize: 9),
                          ),
                        ],
                      ),
                      // O'ng: Kirim (Yashil)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Kirim',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_formatNumber(_calculateIncomeTotal().toInt())} ${_getCurrencySymbol()}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

                      // Filter by date range if filter is active
                      final filtered = transactions.where((t) {
                        if (_filterStartDate == null ||
                            _filterEndDate == null) {
                          return true; // No filter
                        }
                        // Check if transaction date is within the range
                        return t.date.isAfter(_filterStartDate!) &&
                            t.date.isBefore(
                              _filterEndDate!.add(const Duration(days: 1)),
                            );
                      }).toList();
                      final sorted = List<Transaction>.from(filtered)
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
                                    '${_formatNumber(t.amount.toInt())} ${_dataService.getWalletById(_selectedWalletId ?? '')?.currency == 'USD' ? '\$' : 'so\'m'}',
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

  Widget _buildWalletInputTab(
    String displayCurrency,
    String actualCurrency,
    Function(String) onSubmit,
  ) {
    final nameCtrl = TextEditingController();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: nameCtrl,
            decoration: InputDecoration(
              labelText: 'Hamyon nomi',
              hintText: 'Masalan: Asosiy hamyon',
              border: const OutlineInputBorder(),
              suffix: Text(
                displayCurrency,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              onSubmit(name);
            },
            child: const Text('Hamyon yaratish'),
          ),
        ],
      ),
    );
  }

  List<TransactionCategory> _getCategories(TransactionType type) {
    if (type == TransactionType.income) {
      return [
        TransactionCategory.salary,
        TransactionCategory.gift,
        TransactionCategory.investment,
        TransactionCategory.loan,
        TransactionCategory.other,
      ];
    } else {
      return [
        TransactionCategory.grocery,
        TransactionCategory.restaurant,
        TransactionCategory.transport,
        TransactionCategory.utilities,
        TransactionCategory.entertainment,
        TransactionCategory.healthcare,
        TransactionCategory.shopping,
        TransactionCategory.education,
        TransactionCategory.subscription,
        TransactionCategory.other,
      ];
    }
  }

  String _getCategoryName(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.salary:
        return 'Oylik';
      case TransactionCategory.gift:
        return 'Sovg\'a';
      case TransactionCategory.investment:
        return 'Investitsiya';
      case TransactionCategory.loan:
        return 'Kredit';
      case TransactionCategory.grocery:
        return 'Bozor/Oziq-ovqat';
      case TransactionCategory.restaurant:
        return 'Restoran';
      case TransactionCategory.transport:
        return 'Transport/Benzin';
      case TransactionCategory.utilities:
        return 'Kommunal xizmatlar';
      case TransactionCategory.entertainment:
        return 'Ko\'ngilochar';
      case TransactionCategory.healthcare:
        return 'Sog\'liq saqlash';
      case TransactionCategory.shopping:
        return 'Xarid-sotish';
      case TransactionCategory.education:
        return 'Ta\'lim';
      case TransactionCategory.subscription:
        return 'Obuna xizmatlari';
      case TransactionCategory.other:
        return 'Boshqa';
    }
  }

  IconData _getCategoryIcon(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.salary:
        return Icons.work;
      case TransactionCategory.gift:
        return Icons.card_giftcard;
      case TransactionCategory.investment:
        return Icons.trending_up;
      case TransactionCategory.loan:
        return Icons.account_balance;
      case TransactionCategory.grocery:
        return Icons.shopping_cart;
      case TransactionCategory.restaurant:
        return Icons.restaurant;
      case TransactionCategory.transport:
        return Icons.directions_car;
      case TransactionCategory.utilities:
        return Icons.home;
      case TransactionCategory.entertainment:
        return Icons.movie;
      case TransactionCategory.healthcare:
        return Icons.health_and_safety;
      case TransactionCategory.shopping:
        return Icons.shopping_bag;
      case TransactionCategory.education:
        return Icons.school;
      case TransactionCategory.subscription:
        return Icons.subscriptions;
      case TransactionCategory.other:
        return Icons.more_horiz;
    }
  }

  double _calculateExpenseTotal() {
    final transactions = _dataService.getTransactionsByWalletId(
      _selectedWalletId,
    );
    final filtered = transactions.where((t) {
      if (_filterStartDate == null || _filterEndDate == null) {
        return true;
      }
      return t.date.isAfter(_filterStartDate!) &&
          t.date.isBefore(_filterEndDate!.add(const Duration(days: 1)));
    }).toList();

    return filtered
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double _calculateIncomeTotal() {
    final transactions = _dataService.getTransactionsByWalletId(
      _selectedWalletId,
    );
    final filtered = transactions.where((t) {
      if (_filterStartDate == null || _filterEndDate == null) {
        return true;
      }
      return t.date.isAfter(_filterStartDate!) &&
          t.date.isBefore(_filterEndDate!.add(const Duration(days: 1)));
    }).toList();

    return filtered
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  String _getCurrencySymbol() {
    final wallet = _dataService.getWalletById(_selectedWalletId ?? '');
    if (wallet?.currency == 'USD') {
      return '\$';
    }
    return 'so\'m';
  }

  String _formatNumber(int number) {
    // Uzbek number format: spaces as thousands separator
    // Example: 100 000 instead of 100000
    final str = number.toString();
    final reversed = str.split('').reversed.toList();
    final parts = <String>[];

    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        parts.add(' '); // Space instead of comma for Uzbek format
      }
      parts.add(reversed[i]);
    }

    return parts.reversed.join('');
  }
}
