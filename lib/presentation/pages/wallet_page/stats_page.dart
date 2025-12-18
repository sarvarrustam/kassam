import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kassam/presentation/theme/app_colors.dart';
import 'package:kassam/data/models/transaction_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kassam/presentation/pages/wallet_page/bloc/stats_bloc.dart';
import 'package:kassam/core/services/connectivity_service.dart';
import 'package:kassam/presentation/pages/no_internet_page.dart';
import 'dart:convert';

class StatsPage extends StatefulWidget {
  final String? walletId;
  final String? walletName;
  final String? walletCurrency;

  const StatsPage({super.key, this.walletId, this.walletName, this.walletCurrency});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late final StatsBloc _statsBloc;
  // month/year selection removed for simplified stats view
  String? _selectedWalletId;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  bool _showBalance = true; // Balance visibility toggle
  bool _isFetchingTransactionTypes = false; // API dan tur yuklash flag
  List<Map<String, String>> _customCategories = [];
  final ConnectivityService _connectivityService = ConnectivityService();
  
  // API dan kelgan tranzaksiyalar
  List<Transaction> _transactions = [];
  
  // API balance data
  double _kirimTotal = 0.0;
  double _chiqimTotal = 0.0;
  double _currentWalletBalance = 0.0; // Joriy hamyon balansi
  bool _balanceLoaded = false;

  @override
  void initState() {
    super.initState();
    _statsBloc = StatsBloc();
    // Set selected wallet from route parameter
    if (widget.walletId != null) {
      _selectedWalletId = widget.walletId;
    }
    _loadCustomCategories();
    _loadInitialTransactions();
  }

  Future<void> _loadInitialTransactions() async {
    // Sahifa ochilganda tranzaksiyalarni yuklash
    print('🔍 Loading transactions for wallet: $_selectedWalletId');
    
    if (_selectedWalletId != null) {
      final now = DateTime.now();
      final fromDate = DateTime(now.year, now.month, 1);
      final toDate = DateTime(now.year, now.month + 1, 0);
      
      final fromDateStr = '${fromDate.day.toString().padLeft(2, '0')}.${fromDate.month.toString().padLeft(2, '0')}.${fromDate.year}';
      final toDateStr = '${toDate.day.toString().padLeft(2, '0')}.${toDate.month.toString().padLeft(2, '0')}.${toDate.year}';
      
      print('🔍 Date range: $fromDateStr - $toDateStr');
      
      _statsBloc.add(
        StatsGetTransactionsEvent(
          walletId: _selectedWalletId!,
          fromDate: fromDateStr,
          toDate: toDateStr,
        ),
      );
      
      // Balance ham yuklash
      print('🔍 Requesting wallet balance...');
      _statsBloc.add(
        StatsGetWalletBalanceEvent(
          walletId: _selectedWalletId!,
          fromDate: fromDateStr,
          toDate: toDateStr,
        ),
      );
    } else {
      print('❌ Wallet ID is null!');
    }
  }

  @override
  void dispose() {
    _statsBloc.close();
    super.dispose();
  }

  Future<void> _loadCustomCategories() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('custom_categories');
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _customCategories = list
            .map((e) => Map<String, String>.from(e as Map))
            .toList();
      } catch (e) {
        _customCategories = [];
      }
    } else {
      _customCategories = [];
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveCustomCategories() async {
    final sp = await SharedPreferences.getInstance();
    final raw = jsonEncode(_customCategories);
    await sp.setString('custom_categories', raw);
  }

  // ignore: unused_element
  Future<void> _showAddCustomCategoryDialog(
    TransactionType type,
    Function(Map<String, String>) onSaved,
  ) async {
    final nameCtrl = TextEditingController();
    final emojiCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yangi kategoriya qo\'shish'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nomi'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: emojiCtrl,
              decoration: const InputDecoration(
                labelText: 'Emoji (masalan: 🍎)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final emoji = emojiCtrl.text.trim();
              if (name.isEmpty) return;
              final item = {
                'name': name,
                'emoji': emoji.isEmpty ? '📝' : emoji,
                'type': type == TransactionType.income ? 'income' : 'expense',
              };
              _customCategories.add(item);
              _saveCustomCategories();
              onSaved(item);
              Navigator.of(ctx).pop();
            },
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
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




 // shu qism meni tarnzaksiyamni qarzda qo'shish uchun ishlatiladi
  void _showAddTransactionSheet() {
    // Qarzkorlar ro'yxatini yuklash
    _statsBloc.add(const StatsGetDebtorsCreditors());
    
    // Main dialog for transaction
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        TransactionType type = TransactionType.expense;
        String debtType = ''; // bo'sh = oddiy tranzaksiya, 'qarz_olish'/'qarz_berish'/'konvertatsiya'
        TransactionCategory? selectedCategory;
        Map<String, String>? selectedCustomCategory;
        final titleCtrl = TextEditingController();
        final amountCtrl = TextEditingController();
        final debtPersonCtrl = TextEditingController(); // kimga/kimdan
        String? selectedPersonId; // Tanlangan shaxs ID'si
        final walletChiqimCtrl = TextEditingController(); // konvertatsiya uchun
        final walletKirimCtrl = TextEditingController(); // konvertatsiya uchun
        List<dynamic> debtorsList = []; // Qarzkorlar ro'yxati

        return BlocListener<StatsBloc, StatsState>(
          bloc: _statsBloc,
          listener: (context, state) {
            if (state is StatsTransactionCreatedSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
              
              // Tranzaksiyalar ro'yxatini yangilash
              if (_selectedWalletId != null) {
                final now = DateTime.now();
                final fromDate = DateTime(now.year, now.month, 1);
                final toDate = DateTime(now.year, now.month + 1, 0);
                
                final fromDateStr = '${fromDate.day.toString().padLeft(2, '0')}.${fromDate.month.toString().padLeft(2, '0')}.${fromDate.year}';
                final toDateStr = '${toDate.day.toString().padLeft(2, '0')}.${toDate.month.toString().padLeft(2, '0')}.${toDate.year}';
                
                _statsBloc.add(
                  StatsGetTransactionsEvent(
                    walletId: _selectedWalletId!,
                    fromDate: fromDateStr,
                    toDate: toDateStr,
                  ),
                );
                
                // Balance ham yangilash
                _statsBloc.add(
                  StatsGetWalletBalanceEvent(
                    walletId: _selectedWalletId!,
                    fromDate: fromDateStr,
                    toDate: toDateStr,
                  ),
                );
              }
              
              // Refresh UI
              if (mounted) setState(() {});
            } else if (state is StatsTransactionsLoaded) {
              // API dan kelgan tranzaksiyalarni parse qilib mock data ga qo'shish
              if (state.data != null) {
                _parseAndSaveTransactions(state.data);
              }
              // Refresh UI
              if (mounted) setState(() {});
            } else if (state is StatsWalletBalanceLoaded) {
              // Balance data kelganda state'ni yangilash
              print('✅ StatsWalletBalanceLoaded received!');
              print('✅ Kirim: ${state.kirimTotal}');
              print('✅ Chiqim: ${state.chiqimTotal}');
              print('✅ Balance: ${state.walletBalance}');
              
              if (mounted) {
                setState(() {
                  _kirimTotal = state.kirimTotal;
                  _chiqimTotal = state.chiqimTotal;
                  _currentWalletBalance = state.walletBalance; // API'dan kelgan to'g'ridan-to'g'ri balance
                  _balanceLoaded = true;
                  
                  print('📊 Stats page - Kirim: $_kirimTotal');
                  print('📊 Stats page - Chiqim: $_chiqimTotal');
                  print('📊 Stats page - Balance (API): $_currentWalletBalance');
                });
              }
            } else if (state is StatsDebtorsCreditorsLoaded) {
              // Qarzkorlar ro'yxati kelganda
              print('👥 Debtors/creditors loaded: ${state.data}');
              debtorsList = state.data is List ? state.data : [];
            } else if (state is StatsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          child: StatefulBuilder(
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
                          Expanded(
                            child: Row(
                              children: [
                                if (selectedCustomCategory != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(
                                      selectedCustomCategory!['emoji'] ?? '',
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                  )
                                else if (selectedCategory != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(
                                      Transaction(
                                        id: '',
                                        title: '',
                                        amount: 0,
                                        type: type,
                                        category: selectedCategory!,
                                        date: DateTime.now(),
                                      ).getCategoryEmoji(),
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                  ),
                                Text(
                                  selectedCustomCategory != null
                                      ? (selectedCustomCategory!['name'] ??
                                            'Yangi Tranzaksiya')
                                      : (selectedCategory != null
                                            ? _getCategoryName(
                                                selectedCategory!,
                                              )
                                            : 'Yangi Tranzaksiya'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogCtx).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Bitta qatorda scrollable toggle'lar
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Kirim tugmasi
                            GestureDetector(
                              onTap: () {
                                setStateSB(() {
                                  type = TransactionType.income;
                                  debtType = ''; // qarz holatini reset qilish
                                  selectedCategory = null;
                                  selectedCustomCategory = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: type == TransactionType.income
                                      ? Colors.green.shade100
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: type == TransactionType.income
                                        ? Colors.green.shade700
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  'kirim',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: type == TransactionType.income
                                        ? Colors.green.shade700
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Chiqim tugmasi
                            GestureDetector(
                              onTap: () {
                                setStateSB(() {
                                  type = TransactionType.expense;
                                  debtType = ''; // qarz holatini reset qilish
                                  selectedCategory = null;
                                  selectedCustomCategory = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: type == TransactionType.expense
                                      ? Colors.red.shade100
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: type == TransactionType.expense
                                        ? Colors.red.shade700
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  'chiqim',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: type == TransactionType.expense
                                        ? Colors.red.shade700
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Qarz olish tugmasi
                            GestureDetector(
                              onTap: () {
                                setStateSB(() {
                                  debtType = 'qarz_olish';
                                  selectedCategory = null;
                                  selectedCustomCategory = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: debtType == 'qarz_olish'
                                      ? Colors.blue.shade100
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: debtType == 'qarz_olish'
                                        ? Colors.blue.shade700
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  'qarz olish',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: debtType == 'qarz_olish'
                                        ? Colors.blue.shade700
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Qarz berish tugmasi
                            GestureDetector(
                              onTap: () {
                                setStateSB(() {
                                  debtType = 'qarz_berish';
                                  selectedCategory = null;
                                  selectedCustomCategory = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: debtType == 'qarz_berish'
                                      ? Colors.orange.shade100
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: debtType == 'qarz_berish'
                                        ? Colors.orange.shade700
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  'qarz berish',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: debtType == 'qarz_berish'
                                        ? Colors.orange.shade700
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Konvertatsiya tugmasi
                            GestureDetector(
                              onTap: () {
                                setStateSB(() {
                                  debtType = 'konvertatsiya';
                                  selectedCategory = null;
                                  selectedCustomCategory = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: debtType == 'konvertatsiya'
                                      ? Colors.amber.shade100
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: debtType == 'konvertatsiya'
                                        ? Colors.amber.shade700
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  'konvertatsiya',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: debtType == ''
                                        ? Colors.amber.shade700
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Chiqim/Kirim turi tanlash (faqat qarz va konvertatsiya bo'lmasa)
                      if (debtType.isEmpty)
                        InkWell(
                          onTap: () {
                            _openTransactionTypePicker(
                              dialogContext: dialogCtx,
                              transactionType: type,
                              onSelected: (selected) {
                                final selectedName = selected['name'] ?? 'Boshqa';
                                final selectedEmoji = (selected['emoji'] ?? '🏷️').isEmpty
                                    ? '🏷️'
                                    : selected['emoji']!;

                                setStateSB(() {
                                  selectedCategory = TransactionCategory.other;
                                  selectedCustomCategory = {
                                    'name': selectedName,
                                    'emoji': selectedEmoji,
                                    'type': selected['type'] ??
                                        (type == TransactionType.income
                                            ? 'income'
                                            : 'expense'),
                                  };

                                  if ((selected['id'] ?? '').isNotEmpty) {
                                    selectedCustomCategory!['id'] = selected['id']!;
                                  }

                                  // Sarlavhani avtomatik to'ldirmaslik
                                });
                              },
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  selectedCustomCategory != null
                                      ? (selectedCustomCategory!['name'] ?? 'Boshqa')
                                      : (selectedCategory != null
                                            ? _getCategoryName(selectedCategory!)
                                            : (type == TransactionType.income
                                                  ? 'Kirim turi tanlang'
                                                  : 'Chiqim turi tanlang')),
                                  style: TextStyle(
                                    color: selectedCustomCategory != null ||
                                            selectedCategory != null
                                        ? Colors.black
                                        : Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.grey.shade600,
                                ),
                              ],
                            ),
                          ),
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
                      // Konvertatsiya uchun maxsus maydonlar
                      if (debtType == 'konvertatsiya') ...[
                        // Wallet Chiqim
                        TextField(
                          controller: walletChiqimCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Wallet Chiqim (qayerdan)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Wallet Kirim
                        TextField(
                          controller: walletKirimCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Wallet Kirim (qayerga)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Izoh (konvertatsiya uchun)
                        TextField(
                          controller: titleCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Izoh',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Kimga/Kimdan (faqat qarz uchun, konvertatsiya emas)
                      if (debtType.isNotEmpty && debtType != 'konvertatsiya')
                        GestureDetector(
                          onTap: () {
                            // Ro'yxatdan tanlash dialog
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(debtType == 'qarz_olish' ? 'Kimdan' : 'Kimga'),
                                content: SizedBox(
                                  width: double.maxFinite,
                                  child: debtorsList.isEmpty
                                      ? const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(20),
                                            child: Text('Ro\'yxat bo\'sh'),
                                          ),
                                        )
                                      : ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: debtorsList.length,
                                          itemBuilder: (ctx, index) {
                                            final person = debtorsList[index];
                                            final name = person['name']?.toString() ?? '';
                                            final phone = person['telephoneNumber']?.toString() ?? '';
                                            final id = person['id']?.toString() ?? '';
                                            
                                            return ListTile(
                                              title: Text(name),
                                              subtitle: phone.isNotEmpty ? Text(phone) : null,
                                              onTap: () {
                                                setStateSB(() {
                                                  debtPersonCtrl.text = name;
                                                  selectedPersonId = id;
                                                });
                                                Navigator.pop(ctx);
                                              },
                                            );
                                          },
                                        ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Yopish'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: AbsorbPointer(
                            child: TextField(
                              controller: debtPersonCtrl,
                              decoration: InputDecoration(
                                labelText: debtType == 'qarz_olish' ? 'Kimdan' : 'Kimga',
                                border: const OutlineInputBorder(),
                                suffixIcon: const Icon(Icons.arrow_drop_down),
                              ),
                            ),
                          ),
                        ),
                      if (debtType.isNotEmpty && debtType != 'konvertatsiya')
                        const SizedBox(height: 12),
                      // Sarlavha kiritish (konvertatsiya uchun ham)
                      if (debtType != 'konvertatsiya')
                        TextField(
                          controller: titleCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Izoh',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      if (debtType != 'konvertatsiya')
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
                            onPressed: () async {
                              if (_selectedWalletId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Avval hamyon tanlang!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }

                              // Tranzaksiya turini tekshirish
                              if (selectedCustomCategory == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Tranzaksiya turini tanlang!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }

                              final comment = titleCtrl.text.trim();
                              final amount =
                                  double.tryParse(
                                    amountCtrl.text
                                        .replaceAll(' ', '')
                                        .replaceAll(',', '.'),
                                  ) ??
                                  0.0;
                              
                              if (amount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Summani kiriting!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }

                              final transactionTypesId = selectedCustomCategory!['id'] ?? '';
                              if (transactionTypesId.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Tranzaksiya turi ID topilmadi!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }

                              // API type: 'chiqim' yoki 'kirim'
                              final apiType = type == TransactionType.income ? 'kirim' : 'chiqim';

                              // BLoC orqali API'ga transaction yuborish
                              _statsBloc.add(
                                StatsCreateTransactionEvent(
                                  walletId: _selectedWalletId!,
                                  transactionTypesId: transactionTypesId,
                                  type: apiType,
                                  comment: comment,
                                  amount: amount,
                                ),
                              );

                              // Dialog yopish
                              if (mounted) {
                                Navigator.of(dialogCtx).pop();
                              }
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
                                // API orqali yangilash kerak
                                // Hozircha local'da yangila ymiz
                                setState(() {
                                  final index = _transactions.indexWhere((tx) => tx.id == t.id);
                                  if (index != -1) {
                                    _transactions[index] = updated;
                                  }
                                });
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



//shu royhatni dizaynlari hama qismi shu yerda

  @override
  Widget build(BuildContext context) {
    // simplified stats view uses wallet balance and recent transactions

    return BlocProvider<StatsBloc>.value(
      value: _statsBloc,
      child: BlocListener<StatsBloc, StatsState>(
        listener: (context, state) {
          if (state is StatsTransactionCreatedSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
            
            // Tranzaksiya yaratilgandan keyin ro'yxatni yangilash
            if (_selectedWalletId != null) {
              final now = DateTime.now();
              final fromDate = DateTime(now.year, now.month, 1);
              final toDate = DateTime(now.year, now.month + 1, 0);
              
              _statsBloc.add(
                StatsGetTransactionsEvent(
                  walletId: _selectedWalletId!,
                  fromDate: '${fromDate.day.toString().padLeft(2, '0')}.${fromDate.month.toString().padLeft(2, '0')}.${fromDate.year}',
                  toDate: '${toDate.day.toString().padLeft(2, '0')}.${toDate.month.toString().padLeft(2, '0')}.${toDate.year}',
                ),
              );
            }
          } else if (state is StatsTransactionsLoaded) {
            // API dan kelgan tranzaksiyalarni parse qilish
            if (state.data != null) {
              _parseAndSaveTransactions(state.data);
            }
            // UI'ni yangilash
            if (mounted) setState(() {});
          } else if (state is StatsTransactionTypeCreatedSuccess &&
              !_isFetchingTransactionTypes) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is StatsError && !_isFetchingTransactionTypes) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: _buildStatsPage(),
      ),
    );
  }

  Widget _buildStatsPage() {
    return BlocListener<StatsBloc, StatsState>(
      bloc: _statsBloc,
      listener: (context, state) {
        if (state is StatsWalletBalanceLoaded) {
          // Balance data kelganda state'ni yangilash
          print('✅ StatsWalletBalanceLoaded received in main listener!');
          print('✅ Kirim: ${state.kirimTotal}');
          print('✅ Chiqim: ${state.chiqimTotal}');
          print('✅ Balance: ${state.walletBalance}');
          
          if (mounted) {
            setState(() {
              _kirimTotal = state.kirimTotal;
              _chiqimTotal = state.chiqimTotal;
              _currentWalletBalance = state.walletBalance;
              _balanceLoaded = true;
              
              print('📊 Stats page - Kirim updated: $_kirimTotal');
              print('📊 Stats page - Chiqim updated: $_chiqimTotal');
              print('📊 Stats page - Balance updated: $_currentWalletBalance');
            });
          }
        } else if (state is StatsTransactionsLoaded) {
          // API dan kelgan tranzaksiyalarni parse qilib mock data ga qo'shish
          if (state.data != null) {
            _parseAndSaveTransactions(state.data);
          }
          if (mounted) setState(() {});
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.walletName ?? 'Hamyon',
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
      ),
      body: RefreshIndicator(
        color: AppColors.primaryGreen,
        onRefresh: () async {
          // Internet ulanishini tekshirish
          final hasInternet = await _connectivityService.hasInternetConnection();
          if (!hasInternet) {
            if (mounted) {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NoInternetPage(),
                ),
              );
            }
            return;
          }
          
          // Tranzaksiyalarni yangilash
          if (_selectedWalletId != null) {
            final now = DateTime.now();
            final fromDate = DateTime(now.year, now.month, 1);
            final toDate = DateTime(now.year, now.month + 1, 0);
            
            final fromDateStr = '${fromDate.day.toString().padLeft(2, '0')}.${fromDate.month.toString().padLeft(2, '0')}.${fromDate.year}';
            final toDateStr = '${toDate.day.toString().padLeft(2, '0')}.${toDate.month.toString().padLeft(2, '0')}.${toDate.year}';
            
            _statsBloc.add(
              StatsGetTransactionsEvent(
                walletId: _selectedWalletId!,
                fromDate: fromDateStr,
                toDate: toDateStr,
              ),
            );
            
            // Balance ham yangilash
            _statsBloc.add(
              StatsGetWalletBalanceEvent(
                walletId: _selectedWalletId!,
                fromDate: fromDateStr,
                toDate: toDateStr,
              ),
            );
          }
          
          // API chaqiruvini kutish - uzunroq vaqt
          await Future.delayed(const Duration(milliseconds: 1500));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Umumiy Hisob - fixed tepada
              Container(
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
                          widget.walletName ?? 'Umumiy Hisob',
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
                        child: Builder(
                          builder: (context) {
                            print('🎯 Building balance text:');
                            print('   _balanceLoaded: $_balanceLoaded');
                            print('   _currentWalletBalance: $_currentWalletBalance');
                            print('   _showBalance: $_showBalance');
                            
                            return Text(
                              _showBalance
                                  ? '${_formatNumber(_currentWalletBalance.toInt())} ${_getCurrencySymbol()}'
                                  : '••••••',
                              style: Theme.of(context).textTheme.displayMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                              textAlign: TextAlign.center,
                            );
                          }
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
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _balanceLoaded
                                  ? '${_formatNumber(_chiqimTotal.toInt())} ${_getCurrencySymbol()}'
                                  : '${_formatNumber(_calculateExpenseTotal().toInt())} ${_getCurrencySymbol()}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.red.shade300,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
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
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _balanceLoaded
                                  ? '${_formatNumber(_kirimTotal.toInt())} ${_getCurrencySymbol()}'
                                  : '${_formatNumber(_calculateIncomeTotal().toInt())} ${_getCurrencySymbol()}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
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
          // Scrollable tranzaksiyalar ro'yxati
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: () {
                      // Filter by date range if filter is active
                      final filtered = _transactions.where((t) {
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
                        // Rang tanlash: 
                        // Qizil: expense (chiqim), loanGiven (qarz berish)
                        // Yashil: income (kirim), loanTaken (qarz olish)
                        // Sariq: conversion (konvertatsiya). 
                        final isRed = t.type == TransactionType.expense || t.type == TransactionType.loanGiven;
                        final isGreen = t.type == TransactionType.income || t.type == TransactionType.loanTaken;
                        final isConversion = t.type == TransactionType.conversion;
                        
                        final bgGradient = isRed
                            ? const LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 209, 105, 103),
                                  Color(0xFFE53935),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : isConversion
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFFFA726), // Orange
                                      Color(0xFFFFB74D), // Light Orange
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : LinearGradient(
                                    colors: [
                                      AppColors.primaryGreen,
                                      AppColors.primaryGreenLight,
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
                                    const SizedBox(height: 20), // Tepada bo'sh joy
                                    // Faqat konvertatsiya uchun "Ayirboshlash" text
                                    // if (t.type == TransactionType.conversion)
                                    //   const Center(
                                    //     child: Text(
                                    //       '               Ayirboshlash',
                                    //       style: TextStyle(
                                    //         color: Colors.white,
                                    //         fontWeight: FontWeight.bold,
                                    //         fontSize: 18,
                                    //       ),
                                    //     ),
                                    //   ),
                                    // if (t.type == TransactionType.conversion)
                                    //   const SizedBox(height: 12),
                                    // Tranzaksiya turi (customCategoryName)
                                    Text(
                                      t.customCategoryName ?? 'Boshqa', 
                                
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    // Sana
                                    Text(
                                      'Sana: ${t.date.day.toString().padLeft(2, '0')}.${t.date.month.toString().padLeft(2, '0')}.${t.date.year} ${t.date.hour.toString().padLeft(2, '0')}:${t.date.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    
                                    // Konvertatsiya uchun maxsus ko'rinish
                                    if (t.type == TransactionType.conversion)
                                      ...[
                                        if (t.walletChiqim != null && t.walletChiqim!.isNotEmpty)
                                          Text(
                                            'Chiqim: ${t.walletChiqim}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        if (t.walletKirim != null && t.walletKirim!.isNotEmpty)
                                          Text(
                                            'Kirim: ${t.walletKirim}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                      ]
                                    // Qarz olish/berish uchun maxsus ko'rinish
                                    else if (t.type == TransactionType.loanTaken || t.type == TransactionType.loanGiven)
                                      ...[
                                        if (t.counterparty != null && t.counterparty!.isNotEmpty)
                                          Text(
                                            '${t.type == TransactionType.loanTaken ? 'Kimdan' : 'Kimga'}: ${t.counterparty}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        if (t.notes != null && t.notes!.isNotEmpty)
                                          Text(
                                            'Hamyon: ${t.notes}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                      ]
                                    else
                                      // Oddiy tranzaksiyalar uchun hamyon nomi
                                      Text(
                                        'Hamyon: ${t.notes ?? widget.walletName ?? 'Noma\'lum'}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    
                                    // Komment (agar bo'sh bo'lmasa) - eng pastda
                                    if (t.title.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Izoh: ${t.title}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 12), 
                                    // Har bir tranzaksiya turi uchun pastda text - markazda
                                    Center(
                                      child: Text(
                                        t.type == TransactionType.income
                                            ? '                       Kirim'
                                            : t.type == TransactionType.expense
                                                ? '                    Chiqim'
                                                : t.type == TransactionType.conversion
                                                    ? '                       Ayirboshlash'
                                                    : t.type == TransactionType.loanTaken
                                                        ? '                        Qarz pul olish'
                                                        : t.type == TransactionType.loanGiven
                                                            ? '                      Qarz pul berish'
                                                            : 'Boshqa',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const SizedBox(height: 20), // Tepada bo'sh joy
                                  Text(
                                    _showBalance 
                                      ? '${_formatNumber(t.amount.toInt())} ${_getCurrencySymbol()}'
                                      : '••••••',
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
                                        onTap: () {
                                          // Edit disabled - hech narsa qilmaydi
                                        },
                                        child: const Icon(
                                          Icons.edit,
                                          color: Colors.white38,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () {
                                          // Delete disabled - hech narsa qilmaydi
                                        },
                                        child: const Icon(
                                          Icons.delete,
                                          color: Colors.white38,
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

                
                ],
              ),
            ),
          ],
        ),
      ),  // SingleChildScrollView
      ), // RefreshIndicator (body)
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionSheet,
        child: const Icon(Icons.add),
      ),
    ),
  );
  }

  // ignore: unused_element
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

  

  double _calculateExpenseTotal() {
    final filtered = _transactions.where((t) {
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
    final filtered = _transactions.where((t) {
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
    // Use widget.walletCurrency from route parameter
    if (widget.walletCurrency == 'USD' || widget.walletCurrency == 'usd') {
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




//shu qismda ranglarni berb yuvoryapmz bazadan ushab. 
  void _parseAndSaveTransactions(dynamic data) {
    try {
      print('📊 Parsing transactions data: $data');
      
      if (data == null) return;
      
      // API dan list kelishi kerak
      final List<dynamic> transactionsList = data is List ? data : [data];
      
      // Yangi tranzaksiyalar ro'yxati
      final newTransactions = <Transaction>[];
      
      // Sanasiga qarab tartiblash (eskisidan yangisiga, keyin UI da reverse bo'ladi)
      transactionsList.sort((a, b) {
        final dateA = a['date']?.toString() ?? '';
        final dateB = b['date']?.toString() ?? '';
        return dateA.compareTo(dateB); // Eskisi birinchi (UI da teskari bo'ladi)
      });
      
      for (final item in transactionsList) {
        if (item is! Map) continue;
        
        // Parse qilish - documentId'ni ishlatish
        final id = item['documentId']?.toString() ?? 
                   item['id']?.toString() ?? 
                   DateTime.now().millisecondsSinceEpoch.toString();
        
        print('➕ Adding transaction ID: $id');
        
        final amount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
        final typeString = item['type']?.toString().toLowerCase().trim() ?? '';
        final transactionTypeString = item['transactiontype']?.toString().toLowerCase().trim() ?? '';
        print('🔍 Transaction type from API: "${item['type']}" -> parsed: "$typeString"');
        print('🔍 TransactionType field: "${item['transactiontype']}" -> parsed: "$transactionTypeString"');
        
        // Type'ni aniqlash - type field'ini tekshirish
        TransactionType type;
        if (typeString.contains('qarzpulolish') || typeString == 'qarzpulolish') {
          type = TransactionType.loanTaken;
          print('✅ Detected QARZ OLISH - will be GREEN');
        } else if (typeString.contains('qarzpulberish') || typeString == 'qarzpulberish') {
          type = TransactionType.loanGiven;
          print('✅ Detected QARZ BERISH - will be RED');
        } else if (typeString.contains('kirim')) {
          type = TransactionType.income;
          print('✅ Detected KIRIM - will be GREEN');
        } else if (typeString.contains('chiqim')) {
          type = TransactionType.expense;
          print('✅ Detected CHIQIM - will be RED');
        } else if (typeString.contains('konvertatsiya') || typeString.contains('konvert')) {
          type = TransactionType.conversion;
          print('✅ Detected CONVERSION - will be ORANGE');
        } else {
          type = TransactionType.expense; // Default
          print('⚠️ Unknown type: "$typeString" - defaulting to expense');
        }
        final comment = item['comment']?.toString() ?? '';
        final transactionTypeName = item['transactionType']?.toString() ?? 
                                     item['transactionTypeName']?.toString() ?? 
                                     'Boshqa';
        final walletName = item['wallet']?.toString() ?? '';
        
        // Konvertatsiya uchun qo'shimcha ma'lumotlar
        final walletKirim = item['walletKirim']?.toString() ?? '';
        final walletChiqim = item['walletChiqim']?.toString() ?? '';
        
        // Qarz olish/berish uchun qo'shimcha ma'lumotlar
        final counterparty = item['counterparty']?.toString() ?? ''; // Kimdan/Kimga
        final amountDebit = double.tryParse(item['amountdebit']?.toString() ?? '0') ?? 0.0;
        
        // Sana parse qilish - dd.MM.yyyy HH:mm:ss formatidan
        DateTime date = DateTime.now();
        if (item['date'] != null) {
          try {
            final dateStr = item['date'].toString();
            // Format: "12.12.2025 9:25:55" -> DateTime
            final parts = dateStr.split(' ');
            if (parts.length >= 2) {
              final dateParts = parts[0].split('.');
              final timeParts = parts[1].split(':');
              if (dateParts.length == 3 && timeParts.length == 3) {
                date = DateTime(
                  int.parse(dateParts[2]), // year
                  int.parse(dateParts[1]), // month
                  int.parse(dateParts[0]), // day
                  int.parse(timeParts[0]), // hour
                  int.parse(timeParts[1]), // minute
                  int.parse(timeParts[2]), // second
                );
                print('📅 Parsed date: $date from $dateStr');
              }
            }
          } catch (e) {
            print('❌ Date parse error: $e, using now()');
          }
        } else {
          print('⚠️ No date in API response, using now()');
        }
        
        // Transaction yaratish
        final transaction = Transaction(
          id: id,
          title: comment, // Komment title'da
          amount: amount,
          type: type,
          category: TransactionCategory.other,
          date: date,
          walletId: _selectedWalletId,
          customCategoryName: transactionTypeName, // Tranzaksiya turi
          customCategoryEmoji: '🏷️',
          notes: walletName, // Hamyon nomini notes'ga saqlaymiz
          walletKirim: walletKirim,
          walletChiqim: walletChiqim,
          counterparty: counterparty, // Kimdan/Kimga
          amountDebit: amountDebit,   // Qarz summasi
        );
        
        newTransactions.add(transaction);
        print('✅ Added transaction: $transactionTypeName - $comment at $date');
      }
      
      // Yangi tranzaksiyalarni ro'yxatga qo'shish
      setState(() {
        // API'dan kelgan barcha tranzaksiyalarni yangilash
        _transactions.clear(); // Eski tranzaksiyalarni tozalash
        _transactions.addAll(newTransactions); // Yangilarini qo'shish
        print('🔄 Replaced all transactions: ${newTransactions.length} items');
      });
      
      print('✅ Transactions parsed and saved (${transactionsList.length} items)');
    } catch (e, stackTrace) {
      print('❌ Parse error: $e');
      print('Stack trace: $stackTrace');
    }
  }

  void _openTransactionTypePicker({
    required BuildContext dialogContext,
    required TransactionType transactionType,
    required void Function(Map<String, String>) onSelected,
  }) {
    final apiType = transactionType == TransactionType.income ? 'kirim' : 'chiqim';

    _isFetchingTransactionTypes = true;
    _statsBloc.add(StatsGetTransactionTypesEvent(type: apiType));

    showDialog(
      context: dialogContext,
      barrierDismissible: true,
      builder: (pickerCtx) {
        Future<void> showCreateTypeDialog() async {
          final nameCtrl = TextEditingController();
          await showDialog(
            context: pickerCtx,
            builder: (ctx) => AlertDialog(
              title: Text(
                apiType == 'kirim'
                    ? 'Yangi kirim turi'
                    : 'Yangi chiqim turi',
              ),
              content: TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Turi nomi',
                  hintText: 'Masalan: Gaz uchun',
                ),
                textInputAction: TextInputAction.done,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Bekor qilish'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    _statsBloc.add(
                      StatsCreateTransactionTypeEvent(
                        name: name,
                        type: apiType,
                      ),
                    );
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Saqlash'),
                ),
              ],
            ),
          );
        }

        return BlocProvider.value(
          value: _statsBloc,
          child: BlocConsumer<StatsBloc, StatsState>(
            listener: (context, state) {
              if (state is StatsTransactionTypeCreatedSuccess) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.green,
                    ),
                  );
                }

                // Ro'yxatni yangilash uchun qayta yuklash
                _statsBloc.add(StatsGetTransactionTypesEvent(type: apiType));
              }
            },
            builder: (context, state) {
              final searchCtrl = TextEditingController();
              String searchQuery = '';

              Widget buildLoading([String? text]) => SizedBox(
                    height: 180,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(text ?? 'Turlar yuklanmoqda...'),
                      ],
                    ),
                  );

              if (state is StatsLoading) {
                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: buildLoading(),
                  ),
                );
              } else if (state is StatsTransactionTypesLoaded) {
                final allItems = _normalizeTransactionTypeList(
                  state.data,
                  apiType,
                );

                return StatefulBuilder(
                  builder: (context, setDialogState) {
                    // Filter items based on search
                    final items = searchQuery.isEmpty
                        ? allItems
                        : allItems
                            .where((item) => (item['name'] ?? '')
                                .toLowerCase()
                                .contains(searchQuery.toLowerCase()))
                            .toList();

                    final TextButton addButton = TextButton.icon(
                      onPressed: showCreateTypeDialog,
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text(
                        apiType == 'kirim'
                            ? 'Yangi kirim turi qo\'shish'
                            : 'Yangi chiqim turi qo\'shish',
                      ),
                    );

                    Widget listSection;
                    if (items.isEmpty) {
                      listSection = Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(searchQuery.isEmpty
                              ? 'Turlar topilmadi'
                              : 'Hech narsa topilmadi'),
                          const SizedBox(height: 12),
                          addButton,
                        ],
                      );
                    } else {
                      listSection = Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 280,
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: items.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final item = items[index];
                                final displayName =
                                    item['name'] ?? 'Noma\'lum';
                                final emoji =
                                    (item['emoji'] ?? '🏷️').isEmpty
                                        ? '🏷️'
                                        : item['emoji']!;

                                return ListTile(
                                  leading: Text(emoji),
                                  title: Text(displayName),
                                  onTap: () {
                                    Navigator.of(pickerCtx).pop();
                                    onSelected(item);
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          addButton,
                        ],
                      );
                    }

                    return Dialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transactionType == TransactionType.income
                                  ? 'Kirim turi tanlang'
                                  : 'Chiqim turi tanlang',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: searchCtrl,
                              decoration: InputDecoration(
                                hintText: 'Qidirish...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              onChanged: (value) {
                                setDialogState(() {
                                  searchQuery = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            listSection,
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.of(pickerCtx).pop(),
                                child: const Text('Yopish'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              } else if (state is StatsError) {
                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.message,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(pickerCtx).pop(),
                              child: const Text('Yopish'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                _statsBloc.add(
                                  StatsGetTransactionTypesEvent(type: apiType),
                                );
                              },
                              child: const Text('Qayta urinish'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: buildLoading('Yuklanmoqda...'),
                ),
              );
            },
          ),
        );
      },
    ).whenComplete(() {
      _isFetchingTransactionTypes = false;
    });
  }

  List<Map<String, String>> _normalizeTransactionTypeList(
    dynamic data,
    String fallbackType,
  ) {
    final rawList = data is List ? data : [data];
    return rawList
        .where((item) => item != null)
        .map<Map<String, String>>((item) {
          if (item is Map) {
            final normalized = <String, String>{};
            item.forEach((key, value) {
              normalized[key.toString()] = value?.toString() ?? '';
            });
            normalized.putIfAbsent('type', () => fallbackType);
            normalized.putIfAbsent('emoji', () => '🏷️');
            return normalized;
          }
          return {
            'name': item.toString(),
            'type': fallbackType,
            'emoji': '🏷️',
          };
        })
        .toList();
  }
}
