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

  const StatsPage({
    super.key,
    this.walletId,
    this.walletName,
    this.walletCurrency,
  });

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

  // Qarzkorlar ro'yxati (API dan)
  List<dynamic> _debtorsList = [];

  // Dialog refresh callback
  Function? _dialogRefreshCallback;

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
    // Qarzkorlar ro'yxatini oldindan yuklash
    _statsBloc.add(const StatsGetDebtorsCreditors());
  }

  Future<void> _loadInitialTransactions() async {
    // Sahifa ochilganda tranzaksiyalarni yuklash
    print('🔍 Loading transactions for wallet: $_selectedWalletId');

    if (_selectedWalletId != null) {
      final now = DateTime.now();
      final fromDate = DateTime(now.year, now.month, 1);
      final toDate = DateTime(now.year, now.month + 1, 0);

      final fromDateStr =
          '${fromDate.day.toString().padLeft(2, '0')}.${fromDate.month.toString().padLeft(2, '0')}.${fromDate.year}';
      final toDateStr =
          '${toDate.day.toString().padLeft(2, '0')}.${toDate.month.toString().padLeft(2, '0')}.${toDate.year}';

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

  // shu qimsda ano qarz bersh olish biutoni bor
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

  void _showDebtorsDialog(
    BuildContext context,
    String debtType,
    TextEditingController debtPersonCtrl,
    StateSetter setStateSB,
    Function(String?) setSelectedPersonId,
  ) {
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => BlocListener<StatsBloc, StatsState>(
        bloc: _statsBloc,
        listener: (context, state) {
          if (state is StatsDebtorsCreditorsLoaded) {
            if (Navigator.of(ctx).canPop()) {
              (ctx as Element).markNeedsBuild();
            }
          }
        },
        child: StatefulBuilder(
          builder: (context, dialogSetState) {
            _dialogRefreshCallback = dialogSetState;

            List<dynamic> filteredList = List.from(_debtorsList);

            if (searchController.text.isNotEmpty) {
              final query = searchController.text.toLowerCase();
              filteredList = _debtorsList.where((person) {
                final name = person['name']?.toString().toLowerCase() ?? '';
                final phone = person['telephoneNumber']?.toString() ?? '';
                return name.contains(query) ||
                    phone.contains(searchController.text);
              }).toList();
            }

            return AlertDialog(
              title: Text(debtType == 'qarz_olish' ? 'Kimdan' : 'Kimga'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        labelText: 'Qidirish',
                        hintText: 'Ism yoki telefon raqam kiriting',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        dialogSetState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: filteredList.isEmpty && _debtorsList.isNotEmpty
                          ? const Center(child: Text('Hech narsa topilmadi'))
                          : _debtorsList.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text('Ro\'yxat bo\'sh'),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filteredList.length,
                              itemBuilder: (ctx, index) {
                                final person = filteredList[index];
                                final name = person['name']?.toString() ?? '';
                                final phone =
                                    person['telephoneNumber']?.toString() ?? '';
                                final id = person['id']?.toString() ?? '';

                                return ListTile(
                                  title: Text(name),
                                  subtitle: phone.isNotEmpty
                                      ? Text(phone)
                                      : null,
                                  onTap: () {
                                    setStateSB(() {
                                      debtPersonCtrl.text = name;
                                    });
                                    setSelectedPersonId(id);
                                    Navigator.pop(ctx);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _showManualEntryDialog(context, debtPersonCtrl, setStateSB);
                  },
                  child: const Text('Qo\'lda qo\'shish'),
                ),
                TextButton(
                  onPressed: () {
                    _dialogRefreshCallback = null;
                    Navigator.pop(ctx);
                  },
                  child: const Text('Yopish'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // shu qism meni tarnzaksiyamni qarzda qo'shish uchun ishlatiladi. // shu qmsda eka qarz olish bersh pul olish biton

  void _showManualEntryDialog(
    BuildContext context,
    TextEditingController debtPersonCtrl,
    StateSetter setStateSB,
  ) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yangi odam qo\'shish'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Ism',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefon raqam (+998901234567)',
                  hintText: '+998901234567',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                onChanged: (value) {
                  // Telefon raqam formatini tekshirish va to'g'rilash
                  String cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');

                  // Agar bo'sh bo'lsa
                  if (cleaned.isEmpty) {
                    return;
                  }

                  // Agar + bilan boshlanmasa va raqam bor bo'lsa
                  if (!cleaned.startsWith('+')) {
                    cleaned = '+998$cleaned';
                  } else if (cleaned.length > 1 &&
                      !cleaned.startsWith('+998')) {
                    // + bor lekin 998 yo'q
                    cleaned = '+998${cleaned.substring(1)}';
                  }

                  // Maksimal uzunlik: +998901234567 (13 ta belgi)
                  if (cleaned.length > 13) {
                    cleaned = cleaned.substring(0, 13);
                  }

                  // Faqat o'zgargan bo'lsa yangilash
                  if (phoneController.text != cleaned) {
                    phoneController.value = TextEditingValue(
                      text: cleaned,
                      selection: TextSelection.collapsed(
                        offset: cleaned.length,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();

              if (name.isNotEmpty) {
                // Telefon raqam validatsiyasi
                if (phone.isNotEmpty &&
                    !RegExp(r'^\+998\d{9}$').hasMatch(phone)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Telefon raqam to\'g\'ri formatda kiriting: +998901234567',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Yangi odamni darhol ro'yxatga qo'shish (dialog'da ko'rinishi uchun)
                final newPerson = {
                  'id': DateTime.now().millisecondsSinceEpoch
                      .toString(), // Vaqtinchalik ID
                  'name': name,
                  'telephoneNumber': phone,
                };

                setState(() {
                  _debtorsList.add(newPerson);

                  // Dialog'ni ham yangilash
                  if (_dialogRefreshCallback != null) {
                    _dialogRefreshCallback!(() {});
                  }
                });

                // API orqali bazaga qo'shish
                _statsBloc.add(
                  StatsCreateDebtorCreditor(name: name, telephoneNumber: phone),
                );

                // Field'ga ham qo'yish
                setStateSB(() {
                  debtPersonCtrl.text = name;
                });

                // Dialog yopish
                Navigator.pop(ctx);

                // Success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$name ro\'yxatga qo\'shildi!'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ism kiritish majburiy'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Qo\'shish'),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionSheet() {
    print('🔄 Opening new transaction dialog - resetting state...');
    
    // Qarzkorlar ro'yxatini yuklash
    _statsBloc.add(const StatsGetDebtorsCreditors());

    // Main dialog for transaction
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        TransactionType type = TransactionType.expense;
        String debtType =
            ''; // bo'sh = oddiy tranzaksiya, 'qarz_olish'/'qarz_berish'/'konvertatsiya'
        String selectedCurrency = 'UZS'; // valyuta tanlash uchun
        bool isBalanceAffected = true; // qarz balansga ta'sir qiladimi
        TransactionCategory? selectedCategory;
        Map<String, String>? selectedCustomCategory;
        final titleCtrl = TextEditingController();
        final amountCtrl = TextEditingController();
        final debtPersonCtrl = TextEditingController(); // kimga/kimdan
        final walletChiqimCtrl = TextEditingController(); // konvertatsiya uchun
        final walletKirimCtrl = TextEditingController(); // konvertatsiya uchun
        String? selectedPersonId; // Tanlangan shaxs ID'si (moved here)
        
        // Debug: har safar dialog ochilganda controllers bo'sh ekanligini tekshirish
        print('🔍 New dialog opened:');
        print('   - titleCtrl.text: "${titleCtrl.text}"');
        print('   - amountCtrl.text: "${amountCtrl.text}"');
        print('   - debtPersonCtrl.text: "${debtPersonCtrl.text}"');
        print('   - selectedPersonId: $selectedPersonId');
        print('   - debtType: "$debtType"');
        print('   - selectedCurrency: "$selectedCurrency"');
        print('   - type: $type');
        print('   - isBalanceAffected: $isBalanceAffected');

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

                final fromDateStr =
                    '${fromDate.day.toString().padLeft(2, '0')}.${fromDate.month.toString().padLeft(2, '0')}.${fromDate.year}';
                final toDateStr =
                    '${toDate.day.toString().padLeft(2, '0')}.${toDate.month.toString().padLeft(2, '0')}.${toDate.year}';

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
              
              // Dialog yopish
              Navigator.of(dialogCtx).pop();
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
                  _currentWalletBalance = state
                      .walletBalance; // API'dan kelgan to'g'ridan-to'g'ri balance
                  _balanceLoaded = true;

                  print('📊 Stats page - Kirim: $_kirimTotal');
                  print('📊 Stats page - Chiqim: $_chiqimTotal');
                  print(
                    '📊 Stats page - Balance (API): $_currentWalletBalance',
                  );
                });
              }
            } else if (state is StatsDebtorsCreditorsLoaded) {
              // Qarzkorlar ro'yxati kelganda
              print('👥 Debtors/creditors loaded: ${state.data}');
              if (mounted) {
                setState(() {
                  _debtorsList.clear();
                  if (state.data is List) {
                    _debtorsList.addAll(state.data);
                  }
                  print(
                    '👥 Updated _debtorsList: ${_debtorsList.length} items',
                  );

                  // Dialog'ni ham yangilash
                  if (_dialogRefreshCallback != null) {
                    _dialogRefreshCallback!(() {});
                  }
                });
              }
            } else if (state is StatsDebtorCreditorCreated) {
              // Yangi qarzkor/kreditor yaratilganda
              print('👤 New debtor/creditor created: ${state.data}');

              // Yangi odamni darhol ro'yxatga qo'shish
              if (state.data != null && mounted) {
                setState(() {
                  // Yangi odam ma'lumotlarini ro'yxatga qo'shish
                  final newPerson = state.data;
                  _debtorsList.add(newPerson);
                  print('👤 Added new person to list: ${newPerson['name']}');
                });
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );

              // Ro'yxatni qayta yuklash (backup uchun)
              _statsBloc.add(const StatsGetDebtorsCreditors());
            } else if (state is StatsTransactionDebtCreated) {
              // Qarz operatsiyasi yaratilganda
              print('💰 Transaction debt created: ${state.data}');

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

                final fromDateStr =
                    '${fromDate.day.toString().padLeft(2, '0')}.${fromDate.month.toString().padLeft(2, '0')}.${fromDate.year}';
                final toDateStr =
                    '${toDate.day.toString().padLeft(2, '0')}.${toDate.month.toString().padLeft(2, '0')}.${toDate.year}';

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
              
              // Dialog yopish
              Navigator.of(dialogCtx).pop();
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
                                    isBalanceAffected = true; // checkbox reset
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
                                    isBalanceAffected = true; // checkbox reset
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
                                    isBalanceAffected = true; // reset checkbox
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
                                    'qarz pul olish',
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
                                    isBalanceAffected = true;
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
                                    'qarz pul berish',
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
                                    isBalanceAffected = true;
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
                                  final selectedName =
                                      selected['name'] ?? 'Boshqa';
                                  final selectedEmoji =
                                      (selected['emoji'] ?? '🏷️').isEmpty
                                      ? '🏷️'
                                      : selected['emoji']!;

                                  setStateSB(() {
                                    selectedCategory =
                                        TransactionCategory.other;
                                    selectedCustomCategory = {
                                      'name': selectedName,
                                      'emoji': selectedEmoji,
                                      'type':
                                          selected['type'] ??
                                          (type == TransactionType.income
                                              ? 'income'
                                              : 'expense'),
                                    };

                                    if ((selected['id'] ?? '').isNotEmpty) {
                                      selectedCustomCategory!['id'] =
                                          selected['id']!;
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    selectedCustomCategory != null
                                        ? (selectedCustomCategory!['name'] ??
                                              'Boshqa')
                                        : (selectedCategory != null
                                              ? _getCategoryName(
                                                  selectedCategory!,
                                                )
                                              : (type == TransactionType.income
                                                    ? 'Kirim turi tanlang'
                                                    : 'Chiqim turi tanlang')),
                                    style: TextStyle(
                                      color:
                                          selectedCustomCategory != null ||
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
                        ],
                        const SizedBox(height: 12),
                        // Kimga/Kimdan (faqat qarz uchun, konvertatsiya emas)
                        if (debtType.isNotEmpty && debtType != 'konvertatsiya')
                          GestureDetector(
                            onTap: () {
                              // Agar ro'yxat bo'sh bo'lsa, API dan yuklash
                              if (_debtorsList.isEmpty) {
                                _statsBloc.add(
                                  const StatsGetDebtorsCreditors(),
                                );
                                // Biroz kutish
                                Future.delayed(
                                  const Duration(milliseconds: 500),
                                  () {
                                    if (_debtorsList.isNotEmpty) {
                                      // Ro'yxat yuklandi, dialogni ochish
                                      _showDebtorsDialog(
                                        context,
                                        debtType,
                                        debtPersonCtrl,
                                        setStateSB,
                                        (id) => selectedPersonId = id,
                                      );
                                    } else {
                                      // Hali yuklanmagan
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Ro\'yxat yuklanmoqda, iltimos kuting...',
                                          ),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  },
                                );
                              } else {
                                // Ro'yxat bor, darhol ochish
                                _showDebtorsDialog(
                                  context,
                                  debtType,
                                  debtPersonCtrl,
                                  setStateSB,
                                  (id) => selectedPersonId = id,
                                );
                              }
                            },
                            child: AbsorbPointer(
                              child: TextField(
                                controller: debtPersonCtrl,
                                decoration: InputDecoration(
                                  labelText: debtType == 'qarz_olish'
                                      ? 'Kimdan'
                                      : 'Kimga',
                                  border: const OutlineInputBorder(),
                                  suffixIcon: const Icon(Icons.arrow_drop_down),
                                ),
                              ),
                            ),
                          ),
                        if (debtType.isNotEmpty && debtType != 'konvertatsiya')
                          const SizedBox(height: 12),
                        // Summa kiritish (qarz uchun)
                        if (debtType.isNotEmpty && debtType != 'konvertatsiya')
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
                        if (debtType.isNotEmpty && debtType != 'konvertatsiya')
                          const SizedBox(height: 12),
                        // Ko'rinadigan summa display va valyuta dropdown (qarz uchun)
                        if (debtType.isNotEmpty && debtType != 'konvertatsiya')
                          Row(
                            children: [
                              // SumaQarz container
                              Expanded(
                                flex: 3,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'SumaQarz:',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Text(
                                        amountCtrl.text.isNotEmpty
                                            ? '${amountCtrl.text} $selectedCurrency'
                                            : '0 $selectedCurrency',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Valyuta dropdown yonida
                              Expanded(
                                flex: 1,
                                child: Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: DropdownButton<String>(
                                    value: selectedCurrency,
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'UZS',
                                        child: Center(child: Text('UZS')),
                                      ),
                                      DropdownMenuItem(
                                        value: 'USD',
                                        child: Center(child: Text('USD')),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setStateSB(() {
                                        selectedCurrency = value!;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        if (debtType.isNotEmpty && debtType != 'konvertatsiya')
                          const SizedBox(height: 12),
                        // Summa kiritish (oddiy va konvertatsiya uchun)
                        if (debtType.isEmpty || debtType == 'konvertatsiya')
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
                        if (debtType.isEmpty || debtType == 'konvertatsiya')
                          const SizedBox(height: 12),
                        // Konvertatsiya uchun maxsus maydonlar
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

                        // Qarz olish uchun checkbox (balansga ta'sir qilmaslik uchun)
                        if (debtType == 'qarz_olish')
                          Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  // Dialog ko'rsatish
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Diqqat'),
                                      content: const Text(
                                        'Buni tanlasangiz qarzingiz summa hamyon balansiga ta\'sir qilmaydi (+ yoki - bo\'lmaydi).\n\nDavom etasizmi?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Yo\'q'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            setStateSB(() {
                                              isBalanceAffected =
                                                  !isBalanceAffected;
                                            });
                                            Navigator.pop(ctx);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  isBalanceAffected
                                                      ? 'Qarz balansga ta\'sir qiladi'
                                                      : 'Qarz balansga ta\'sir qilmaydi',
                                                ),
                                                backgroundColor:
                                                    isBalanceAffected
                                                    ? Colors.green
                                                    : Colors.orange,
                                                duration: const Duration(
                                                  seconds: 2,
                                                ),
                                              ),
                                            );
                                          },
                                          child: const Text('Ha'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: !isBalanceAffected
                                        ? Colors.orange.shade50
                                        : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: !isBalanceAffected
                                          ? Colors.orange.shade300
                                          : Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        !isBalanceAffected
                                            ? Icons.check_box
                                            : Icons.check_box_outline_blank,
                                        color: !isBalanceAffected
                                            ? Colors.orange.shade700
                                            : Colors.grey.shade600,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Aval olgan qarizim',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: !isBalanceAffected
                                                    ? Colors.orange.shade700
                                                    : Colors.grey.shade700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Qarz summasi hamyon balansiga qo\'shilmaydi',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),

                        // Qarz berish uchun checkbox (balansga ta'sir qilmaslik uchun)
                        if (debtType == 'qarz_berish')
                          Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  // Dialog ko'rsatish
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Diqqat'),
                                      content: const Text(
                                        'Buni tanlasangiz berayotgan qarzingiz summa hamyon balansiga ta\'sir qilmaydi (+ yoki - bo\'lmaydi).\n\nDavom etasizmi?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Yo\'q'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            setStateSB(() {
                                              isBalanceAffected =
                                                  !isBalanceAffected;
                                            });
                                            Navigator.pop(ctx);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  isBalanceAffected
                                                      ? 'Berayotgan qarz balansga ta\'sir qiladi'
                                                      : 'Berayotgan qarz balansga ta\'sir qilmaydi',
                                                ),
                                                backgroundColor:
                                                    isBalanceAffected
                                                    ? Colors.green
                                                    : Colors.orange,
                                                duration: const Duration(
                                                  seconds: 2,
                                                ),
                                              ),
                                            );
                                          },
                                          child: const Text('Ha'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: !isBalanceAffected
                                        ? Colors.orange.shade50
                                        : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: !isBalanceAffected
                                          ? Colors.orange.shade300
                                          : Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        !isBalanceAffected
                                            ? Icons.check_box
                                            : Icons.check_box_outline_blank,
                                        color: !isBalanceAffected
                                            ? Colors.orange.shade700
                                            : Colors.grey.shade600,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Aval bergan qarzim',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: !isBalanceAffected
                                                    ? Colors.orange.shade700
                                                    : Colors.grey.shade700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Berayotgan qarz summasi hamyon balansidan ayrilmaydi',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),

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

                                // Qarz operatsiyalari uchun
                                if (debtType == 'qarz_olish' ||
                                    debtType == 'qarz_berish') {
                                  // Shaxsni tekshirish
                                  if (selectedPersonId == null ||
                                      selectedPersonId!.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Iltimos, shaxsni tanlang!',
                                        ),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                    return;
                                  }

                                  // Qarz operatsiyasi API'si
                                  _statsBloc.add(
                                    StatsCreateTransactionDebt(
                                      transactionTypesId:
                                          debtType == 'qarz_berish'
                                          ? '20b88c22-d51d-11f0-8059-c888ab3416b4' // Hardcoded for now
                                          : '20b88c22-d51d-11f0-8059-c888ab3416b4', // Should be different for qarz_olish
                                      type: debtType == 'qarz_berish'
                                          ? 'qarzPulBerish'
                                          : 'qarzPulOlish',
                                      walletId: _selectedWalletId!,
                                      debtorCreditorId: selectedPersonId!,
                                      previousDebt: !isBalanceAffected, // Checkbox bosilsa true bo'ladi
                                      currency: selectedCurrency.toLowerCase(),
                                      amount: amount,
                                      amountDebt: amount,
                                      comment: comment.isNotEmpty
                                          ? comment
                                          : null,
                                    ),
                                  );
                                } else {
                                  // Oddiy tranzaksiya uchun
                                  // Tranzaksiya turini tekshirish
                                  if (selectedCustomCategory == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Tranzaksiya turini tanlang!',
                                        ),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                    return;
                                  }

                                  final transactionTypesId =
                                      selectedCustomCategory!['id'] ?? '';
                                  if (transactionTypesId.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Tranzaksiya turi ID topilmadi!',
                                        ),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                    return;
                                  }

                                  // API type: 'chiqim' yoki 'kirim'
                                  final apiType = type == TransactionType.income
                                      ? 'kirim'
                                      : 'chiqim';

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
                                }

                                // Dialog yopish - commented out, listener da yopiladi
                                // if (mounted) {
                                //   Navigator.of(dialogCtx).pop();
                                // }
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

  // TODO: Edit transaction functionality - will be implemented later
  // ignore: unused_element
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
                                  final index = _transactions.indexWhere(
                                    (tx) => tx.id == t.id,
                                  );
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
                  fromDate:
                      '${fromDate.day.toString().padLeft(2, '0')}.${fromDate.month.toString().padLeft(2, '0')}.${fromDate.year}',
                  toDate:
                      '${toDate.day.toString().padLeft(2, '0')}.${toDate.month.toString().padLeft(2, '0')}.${toDate.year}',
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
          title: Text(widget.walletName ?? 'Hamyon'),
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
            final hasInternet = await _connectivityService
                .hasInternetConnection();
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

              final fromDateStr =
                  '${fromDate.day.toString().padLeft(2, '0')}.${fromDate.month.toString().padLeft(2, '0')}.${fromDate.year}';
              final toDateStr =
                  '${toDate.day.toString().padLeft(2, '0')}.${toDate.month.toString().padLeft(2, '0')}.${toDate.year}';

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
                      colors: [
                        AppColors.primaryGreen,
                        AppColors.primaryGreenLight,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          Center(
                            child: Text(
                              widget.walletName ?? 'Umumiy Hisob',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.white),
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
                                print(
                                  '   _currentWalletBalance: $_currentWalletBalance',
                                );
                                print('   _showBalance: $_showBalance');

                                return Text(
                                  _showBalance
                                      ? '${_formatNumber(_currentWalletBalance.toInt())} ${_getCurrencySymbol()}'
                                      : '••••••',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                  textAlign: TextAlign.center,
                                );
                              },
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
                                    ?.copyWith(
                                      color: Colors.white70,
                                      fontSize: 9,
                                    ),
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
                            final isRed =
                                t.type == TransactionType.expense ||
                                t.type == TransactionType.loanGiven;
                            final isConversion =
                                t.type == TransactionType.conversion;

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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(
                                          height: 20,
                                        ), // Tepada bo'sh joy
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
                                        if (t.type ==
                                            TransactionType.conversion) ...[
                                          if (t.walletChiqim != null &&
                                              t.walletChiqim!.isNotEmpty)
                                            Text(
                                              'Chiqim: ${t.walletChiqim}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          const SizedBox(height: 4),
                                          if (t.walletKirim != null &&
                                              t.walletKirim!.isNotEmpty)
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
                                        else if (t.type ==
                                                TransactionType.loanTaken ||
                                            t.type ==
                                                TransactionType.loanGiven) ...[
                                          if (t.counterparty != null &&
                                              t.counterparty!.isNotEmpty)
                                            Text(
                                              '${t.type == TransactionType.loanTaken ? 'Kimdan' : 'Kimga'}: ${t.counterparty}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          const SizedBox(height: 4),
                                          if (t.notes != null &&
                                              t.notes!.isNotEmpty)
                                            Text(
                                              'Hamyon: ${t.notes}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                        ] else
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
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
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
                                                : t.type ==
                                                      TransactionType.expense
                                                ? '                    Chiqim'
                                                : t.type ==
                                                      TransactionType.conversion
                                                ? '                       Ayirboshlash'
                                                : t.type ==
                                                      TransactionType.loanTaken
                                                ? '                        Qarz pul olish'
                                                : t.type ==
                                                      TransactionType.loanGiven
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
                                      const SizedBox(
                                        height: 20,
                                      ), // Tepada bo'sh joy
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
          ), // SingleChildScrollView
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
        return dateA.compareTo(
          dateB,
        ); // Eskisi birinchi (UI da teskari bo'ladi)
      });

      for (final item in transactionsList) {
        if (item is! Map) continue;

        // Parse qilish - documentId'ni ishlatish
        final id =
            item['documentId']?.toString() ??
            item['id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString();

        print('➕ Adding transaction ID: $id');

        final amount =
            double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
        final typeString = item['type']?.toString().toLowerCase().trim() ?? '';
        final transactionTypeString =
            item['transactiontype']?.toString().toLowerCase().trim() ?? '';
        print(
          '🔍 Transaction type from API: "${item['type']}" -> parsed: "$typeString"',
        );
        print(
          '🔍 TransactionType field: "${item['transactiontype']}" -> parsed: "$transactionTypeString"',
        );

        // Type'ni aniqlash - type field'ini tekshirish
        TransactionType type;
        if (typeString.contains('qarzpulolish') ||
            typeString == 'qarzpulolish') {
          type = TransactionType.loanTaken;
          print('✅ Detected QARZ OLISH - will be GREEN');
        } else if (typeString.contains('qarzpulberish') ||
            typeString == 'qarzpulberish') {
          type = TransactionType.loanGiven;
          print('✅ Detected QARZ BERISH - will be RED');
        } else if (typeString.contains('kirim')) {
          type = TransactionType.income;
          print('✅ Detected KIRIM - will be GREEN');
        } else if (typeString.contains('chiqim')) {
          type = TransactionType.expense;
          print('✅ Detected CHIQIM - will be RED');
        } else if (typeString.contains('konvertatsiya') ||
            typeString.contains('konvert')) {
          type = TransactionType.conversion;
          print('✅ Detected CONVERSION - will be ORANGE');
        } else {
          type = TransactionType.expense; // Default
          print('⚠️ Unknown type: "$typeString" - defaulting to expense');
        }
        final comment = item['comment']?.toString() ?? '';
        final transactionTypeName =
            item['transactionType']?.toString() ??
            item['transactionTypeName']?.toString() ??
            'Boshqa';
        final walletName = item['wallet']?.toString() ?? '';

        // Konvertatsiya uchun qo'shimcha ma'lumotlar
        final walletKirim = item['walletKirim']?.toString() ?? '';
        final walletChiqim = item['walletChiqim']?.toString() ?? '';

        // Qarz olish/berish uchun qo'shimcha ma'lumotlar
        final counterparty =
            item['counterparty']?.toString() ?? ''; // Kimdan/Kimga
        final amountDebit =
            double.tryParse(item['amountdebit']?.toString() ?? '0') ?? 0.0;

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
          amountDebit: amountDebit, // Qarz summasi
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

      print(
        '✅ Transactions parsed and saved (${transactionsList.length} items)',
      );
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
    final apiType = transactionType == TransactionType.income
        ? 'kirim'
        : 'chiqim';

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
                apiType == 'kirim' ? 'Yangi kirim turi' : 'Yangi chiqim turi',
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
                              .where(
                                (item) => (item['name'] ?? '')
                                    .toLowerCase()
                                    .contains(searchQuery.toLowerCase()),
                              )
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
                          Text(
                            searchQuery.isEmpty
                                ? 'Turlar topilmadi'
                                : 'Hech narsa topilmadi',
                          ),
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
                                final displayName = item['name'] ?? 'Noma\'lum';
                                final emoji = (item['emoji'] ?? '🏷️').isEmpty
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
    return rawList.where((item) => item != null).map<Map<String, String>>((
      item,
    ) {
      if (item is Map) {
        final normalized = <String, String>{};
        item.forEach((key, value) {
          normalized[key.toString()] = value?.toString() ?? '';
        });
        normalized.putIfAbsent('type', () => fallbackType);
        normalized.putIfAbsent('emoji', () => '🏷️');
        return normalized;
      }
      return {'name': item.toString(), 'type': fallbackType, 'emoji': '🏷️'};
    }).toList();
  }
}
