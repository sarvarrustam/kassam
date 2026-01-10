import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kassam/presentation/theme/app_colors.dart';
import 'package:kassam/data/models/transaction_model.dart';
import 'package:kassam/data/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kassam/presentation/pages/wallet_page/bloc/stats_bloc.dart';
import 'package:kassam/core/services/connectivity_service.dart';
import 'package:kassam/presentation/pages/no_internet_page.dart';
import 'dart:convert';
import 'package:kassam/core/services/number_formatter.dart';
import 'package:url_launcher/url_launcher.dart';

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
  Set<String> _deletingTransactionIds = {}; // O'chirilayotgan tranzaksiyalar ID lari
  bool _isCreatingTransaction = false; // Oddiy tranzaksiya yaratish
  bool _isCreatingDebtTransaction = false; // Qarz tranzaksiyasi yaratish
  bool _isCreatingConversion = false; // Konvertatsiya yaratish
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

  // Walletlar ro'yxati (konvertatsiya uchun)
  List<Map<String, dynamic>> _walletsList = [];

  // Exchange rate (default 12000, but will be loaded from SharedPreferences)
  double _exchangeRate = 12000.0;

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
    // _loadExchangeRate() olib tashlandi - kurs endi tranzaksiyalardan kelyapti
    _loadCustomCategories();
    _loadInitialTransactions();
    // _loadWalletsList() olib tashlandi - faqat konvertatsiya dialogida kerak bo'lganda yuklanadi
  }

  Future<void> _loadExchangeRate() async {
    try {
      final sp = await SharedPreferences.getInstance();
      // Kursni SharedPreferences dan olish (default 12000)
      final savedRate = sp.getDouble('exchange_rate_usd') ?? 12000.0;
      setState(() {
        _exchangeRate = savedRate;
      });
      print('📊 Exchange rate loaded from SP: $_exchangeRate');

      // API dan yangi kurs olishga urindi (optional)
      try {
        final apiService = ApiService();
        final response = await apiService.getExchangeRate();
        if (response['success'] == true && response['data'] != null) {
          final apiRate = (response['data']['kurs'] ?? savedRate).toDouble();
          if (apiRate != savedRate) {
            // Yangi kursni saqlash
            await sp.setDouble('exchange_rate_usd', apiRate);
            setState(() {
              _exchangeRate = apiRate;
            });
            print('📊 Exchange rate updated from API: $_exchangeRate');
          }
        }
      } catch (apiError) {
        print('⚠️ Could not fetch rate from API: $apiError');
        // SharedPreferences dan olingan qiymat qoladi
      }
    } catch (e) {
      print('❌ Error loading exchange rate: $e');
      // Default qiymat qoladi (12000.0)
    }
  }

  Future<void> _loadWalletsList() async {
    print('📱 Starting _loadWalletsList method...');
    try {
      final sp = await SharedPreferences.getInstance();
      final userToken =
          sp.getString('auth_token') ?? sp.getString('token') ?? '';

      print(
        '📱 Loading wallets with token: ${userToken.isEmpty ? "EMPTY" : "EXISTS"}',
      );

      if (userToken.isEmpty) {
        print('❌ No user token for wallets');
        return;
      }

      final apiService = ApiService();
      final response = await apiService.get(
        apiService.getWalletsBalans,
        token: userToken,
      );

      print('📱 API Response: $response');

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> walletsData = response['data'] is List
            ? response['data']
            : (response['data']['wallets'] ?? []);

        print('📱 Raw walletsData: $walletsData');

        // Har bir wallet uchun alohida debug
        walletsData.forEach((wallet) {
          print('🔍 Wallet raw: $wallet');
          print('   - balance field: ${wallet['balance']}');
          print('   - balans field: ${wallet['balans']}');
          print('   - amount field: ${wallet['amount']}');
          print('   - suma field: ${wallet['suma']}');
          print('   - value field: ${wallet['value']} ← ACTUAL BALANCE');
        });

        setState(() {
          _walletsList = walletsData
              .map(
                (wallet) => {
                  'walletId':
                      wallet['walletId']?.toString() ??
                      wallet['id']?.toString() ??
                      '',
                  'name': wallet['name']?.toString() ?? 'Wallet',
                  'walletName':
                      wallet['name']?.toString() ??
                      'Wallet', // walletName qo'shildi
                  'currency':
                      wallet['currency']?.toString() ??
                      wallet['type']?.toString().toUpperCase() ??
                      'UZS',
                  'balance':
                      (wallet['value'] ??
                              wallet['balance'] ??
                              wallet['balans'] ??
                              wallet['amount'] ??
                              wallet['suma'] ??
                              0.0)
                          .toDouble(),
                },
              )
              .toList();
        });
        print('📱 Loaded ${_walletsList.length} wallets for conversion');
        _walletsList.forEach((w) {
          print(
            '   💰 ${w['name']} / ${w['walletName']} (${w['currency']}) - Balance: ${w['balance']} - ID: ${w['walletId']}',
          );
        });
      } else {
        print(
          '❌ Failed to load wallets: ${response['message'] ?? response['error']}',
        );
        print('❌ Full response: $response');
      }
    } catch (e) {
      print('❌ Error loading wallets: $e');
    }
  }

  @override
  void dispose() {
    _statsBloc.close();
    super.dispose();
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

      // API: GET /transaction/list - Tranzaksiyalar ro'yxatini olish
      _statsBloc.add(
        StatsGetTransactionsEvent(
          walletId: _selectedWalletId!,
          fromDate: fromDateStr,
          toDate: toDateStr,
        ),
      );

      // API: GET /wallet/balance - Hamyon balansini olish
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

  // @override
  // void dispose() {
  //   _statsBloc.close();
  //   super.dispose();
  // }

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

  Widget _buildDebtRow(
    String label,
    double amount,
    String currency,
    Color color,
  ) {
    print(
      '🔍 _buildDebtRow: $label = $amount $currency (showing: ${amount > 0})',
    );
    if (amount <= 0) {
      return const SizedBox.shrink(); // 0 bo'lsa ko'rsatmaymiz
    }

    String formattedAmount;
    if (currency == 'UZS') {
      formattedAmount = amount.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]} ',
      );
    } else {
      formattedAmount = amount.toStringAsFixed(2);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          Text(
            '$formattedAmount $currency',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showDebtorsDialog(
    BuildContext context,
    String debtType,
    TextEditingController debtPersonCtrl,
    StateSetter setStateSB,
    Function(String?) setSelectedPersonId,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (dialogContext) => _buildDebtorsDialogScreen(
          dialogContext,
          debtType,
          debtPersonCtrl,
          setStateSB,
          setSelectedPersonId,
        ),
      ),
    );
  }

  Widget _buildDebtorsDialogScreen(
    BuildContext dialogContext,
    String debtType,
    TextEditingController debtPersonCtrl,
    StateSetter setStateSB,
    Function(String?) setSelectedPersonId,
  ) {
    return WillPopScope(
      onWillPop: () async {
        // Dialog yopilganda callback'ni tozalash
        _dialogRefreshCallback = null;
        print('🧹 Dialog closed, callback cleared');
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(debtType == 'qarz_olish' ? 'Kimdan' : 'Kimga'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _dialogRefreshCallback = null;
              print('🧹 Dialog manually closed, callback cleared');
              Navigator.pop(dialogContext);
            },
          ),
        ),
        body: _buildDebtorsDialogContent(
          dialogContext,
          debtType,
          debtPersonCtrl,
          setStateSB,
          setSelectedPersonId,
        ),
      ),
    );
  }

  Widget _buildDebtorsDialogContent(
    BuildContext dialogContext,
    String debtType,
    TextEditingController debtPersonCtrl,
    StateSetter setStateSB,
    Function(String?) setSelectedPersonId,
  ) {
    final searchController = TextEditingController();

    return BlocListener<StatsBloc, StatsState>(
      bloc: _statsBloc,
      listener: (listenerContext, state) {
        if (state is StatsDebtorsCreditorsLoaded) {
          if (Navigator.of(listenerContext).canPop()) {
            (listenerContext as Element).markNeedsBuild();
          }
        }
      },
      child: StatefulBuilder(
        builder: (builderContext, dialogSetState) {
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

          return RefreshIndicator(
            onRefresh: () async {
              // API: GET /debtor-creditor/list - Pull to refresh
              _statsBloc.add(const StatsGetDebtorsCreditors());
              
              // 1 soniya kutamiz (API javobi kelguncha)
              await Future.delayed(const Duration(seconds: 1));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                children: [
                  Expanded(
                    child: TextField(
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
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF10b981),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      tooltip: 'Yangi odam qo\'shish',
                      onPressed: () {
                        _showManualEntryDialog(dialogContext, debtPersonCtrl, setStateSB);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (filteredList.isEmpty && _debtorsList.isNotEmpty)
                const Center(child: Text('Hech narsa topilmadi'))
              else if (_debtorsList.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Ro\'yxat bo\'sh'),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredList.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, index) {
                    final person = filteredList[index];
                    final name = person['name']?.toString() ?? '';
                    final phone = person['telephoneNumber']?.toString() ?? '';
                    final id = person['id']?.toString() ?? '';

                    // API dan kelgan to'g'ri qarz miqdorlari
                    final apiUzsXaqqim =
                        double.tryParse(
                          person['uzsXaqqim']?.toString() ?? '0',
                        ) ??
                        0.0;
                    final apiUzsQarzim =
                        double.tryParse(
                          person['uzsQarzim']?.toString() ?? '0',
                        ) ??
                        0.0;
                    final apiUsdXaqqim =
                        double.tryParse(
                          person['usdXaqqim']?.toString() ?? '0',
                        ) ??
                        0.0;
                    final apiUsdQarzim =
                        double.tryParse(
                          person['usdQarzim']?.toString() ?? '0',
                        ) ??
                        0.0;

                    // Faqat API ma'lumotlarini ko'rsatish
                    final uzsXaqqim = apiUzsXaqqim;
                    final uzsQarzim = apiUzsQarzim;
                    final usdXaqqim = apiUsdXaqqim;
                    final usdQarzim = apiUsdQarzim;

                    print(
                      '🔍 Processing $name (ID: ${id.substring(0, 8)}...):',
                    );
                    print(
                      '   API: UZS($uzsXaqqim/$uzsQarzim) USD($usdXaqqim/$usdQarzim)',
                    );

                    // Debug: har bir odam uchun ma'lumotlarni ko'rsatish
                    bool hasAnyDebt =
                        uzsXaqqim > 0 ||
                        uzsQarzim > 0 ||
                        usdXaqqim > 0 ||
                        usdQarzim > 0;
                    print(
                      '👤 $name (ID: ${id.substring(0, 8)}...): UZS($uzsXaqqim/$uzsQarzim) USD($usdXaqqim/$usdQarzim) HasDebt: $hasAnyDebt',
                    );

                    // Faqat qarz bor bo'lganda debug chiqarish
                    if (uzsXaqqim > 0 ||
                        uzsQarzim > 0 ||
                        usdXaqqim > 0 ||
                        usdQarzim > 0) {
                      print(
                        '💰 $name - UZS: ${uzsXaqqim.toInt()}/${uzsQarzim.toInt()}, USD: ${usdXaqqim}/${usdQarzim}',
                      );
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: Icon(
                            Icons.person,
                            color: Colors.blue.shade600,
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (phone.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      phone,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () async {
                                      final Uri launchUri = Uri(
                                        scheme: 'tel',
                                        path: phone,
                                      );
                                      if (await canLaunchUrl(launchUri)) {
                                        await launchUrl(launchUri);
                                      } else {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Telefon qo\'ng\'iroqini amalga oshirib bo\'lmadi'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.phone,
                                        size: 18,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            // 4 ta qarz miqdori alohida qatorlarda
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Column(
                                children: [
                                  _buildDebtRow(
                                    'UZS Haqqim',
                                    uzsXaqqim,
                                    'UZS',
                                    Colors.green,
                                  ),
                                  _buildDebtRow(
                                    'USD Haqqim',
                                    usdXaqqim,
                                    'USD',
                                    Colors.green,
                                  ),
                                  _buildDebtRow(
                                    'UZS Qarzim',
                                    uzsQarzim,
                                    'UZS',
                                    Colors.red,
                                  ),
                                  _buildDebtRow(
                                    'USD Qarzim',
                                    usdQarzim,
                                    'USD',
                                    Colors.red,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey.shade400,
                        ),
                        onTap: () {
                          setStateSB(() {
                            debtPersonCtrl.text = name;
                          });
                          setSelectedPersonId(id);
                          _dialogRefreshCallback = null;
                          print('🧹 Person selected, callback cleared');
                          Navigator.pop(dialogContext);
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
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

              // Ism va telefon raqam ikkalasi ham bo'lishi kerak
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ism kiritish majburiy'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (phone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Telefon raqam kiritish majburiy'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Telefon raqam formatini tekshirish
              if (!RegExp(r'^\+998\d{9}$').hasMatch(phone)) {
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

              // API: POST /debtor-creditor/create - Yangi qarzkor/kreditor yaratish
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
            },
            child: const Text('Qo\'shish'),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionSheet() {
    print('🔄 Opening new transaction dialog - resetting state...');

    // StatsGetDebtorsCreditors() olib tashlandi - + tugmasi bosilganda API chaqirilmasin
    // Faqat ichkaridagi qarz tugmalarini bosganda API chaqiriladi

    // Main dialog for transaction
    // Fullscreen navigation bilan ochish
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (transactionContext) => _buildTransactionDialog(transactionContext),
      ),
    );
  }

  Widget _buildTransactionDialog(BuildContext transactionContext) {
    return WillPopScope(
      onWillPop: () async {
        // Telefon back tugmasi - dialogni yopish
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tranzaksiya'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(transactionContext),
          ),
        ),
        body: _buildTransactionDialogContent(),
      ),
    );
  }

  Widget _buildTransactionDialogContent() {
    return Builder(
      builder: (dialogCtx) {
        TransactionType type = TransactionType.expense;
        String debtType =
            ''; // bo'sh = oddiy tranzaksiya, 'qarz_olish'/'qarz_berish'/'konvertatsiya'
        String selectedCurrency =
            widget.walletCurrency?.toUpperCase() ??
            'UZS'; // hamyon valyutasidan olish
        String displayedAmount = '0'; // SumaQarz ko'rinishi uchun
        bool isBalanceAffected = true; // qarz balansga ta'sir qiladimi
        TransactionCategory? selectedCategory;
        Map<String, String>? selectedCustomCategory;
        final titleCtrl = TextEditingController();
        final amountCtrl = TextEditingController();
        final debtPersonCtrl = TextEditingController(); // kimga/kimdan
        final chiqimAmountCtrl =
            TextEditingController(); // konvertatsiya chiqim
        final kirimAmountCtrl = TextEditingController(); // konvertatsiya kirim
        String? selectedPersonId; // Tanlangan shaxs ID'si (moved here)
        String? selectedWalletChiqimId; // Konvertatsiya: qayerdan
        String? selectedWalletKirimId; // Konvertatsiya: qayerga

        // Form ma'lumotlarini tozalash funksiyasi
        void clearFormData() {
          titleCtrl.clear();
          amountCtrl.clear();
          debtPersonCtrl.clear();
          chiqimAmountCtrl.clear();
          kirimAmountCtrl.clear();
          selectedPersonId = null;
          selectedWalletChiqimId = null;
          selectedWalletKirimId = null;
          selectedCategory = null;
          selectedCustomCategory = null;
          displayedAmount = '0';
          isBalanceAffected = true;
          selectedCurrency = widget.walletCurrency?.toUpperCase() ?? 'UZS';
          print('🧹 Form cleared!');
        }

        // Debug: har safar dialog ochilganda controllers bo'sh ekanligini tekshirish
        print('🔍 New dialog opened:');
        print('   - walletCurrency: "${widget.walletCurrency}"');
        print('   - selectedCurrency (default): "$selectedCurrency"');
        print('   - titleCtrl.text: "${titleCtrl.text}"');
        print('   - amountCtrl.text: "${amountCtrl.text}"');
        print('   - debtPersonCtrl.text: "${debtPersonCtrl.text}"');
        print('   - selectedPersonId: $selectedPersonId');
        print('   - debtType: "$debtType"');
        print('   - displayedAmount: "$displayedAmount"');
        print('   - type: $type');
        print('   - isBalanceAffected: $isBalanceAffected');

        return BlocListener<StatsBloc, StatsState>(
          bloc: _statsBloc,
          listener: (context, state) {
            // Barcha state'larni log qilish (faqat muhim debug uchun)
            if (state.toString().contains('Error') ||
                state.toString().contains('error')) {
              print('🔄 BlocListener received state: ${state.runtimeType}');
            }

            if (state is StatsTransactionCreatedSuccess) {
              // Loading holatlarini o'chirish
              if (mounted) {
                setState(() {
                  _isCreatingTransaction = false;
                  _isCreatingConversion = false;
                });
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );

              // Agar konvertatsiya bo'lsa - hamma walletlarni yangilash
              if (state.message.contains('Konvertatsiya') ||
                  state.message.contains('konvert')) {
                // Barcha walletlarning balansini yangilash (konvertatsiya 2 ta walletni ta'sir qiladi)
                _loadWalletsList(); // Walletlar ro'yxatini qayta yuklash

                // Manual konvertatsiya tranzaksiyasi yaratish (API summalarni saqlamaydi)
                // Note: Bu temporary solution - ideally API should return correct amounts
                print(
                  '⚠️ Creating manual conversion transaction since API doesn\'t store amounts',
                );
              }

              // Tranzaksiya yaratilgandan keyin ma'lumotlarni yangilash
              if (_selectedWalletId != null) {
                final now = DateTime.now();
                final fromDate = DateTime(now.year, now.month, 1);
                final toDate = DateTime(now.year, now.month + 1, 0);

                final fromDateStr =
                    '${fromDate.day.toString().padLeft(2, '0')}.${fromDate.month.toString().padLeft(2, '0')}.${fromDate.year}';
                final toDateStr =
                    '${toDate.day.toString().padLeft(2, '0')}.${toDate.month.toString().padLeft(2, '0')}.${toDate.year}';

                // API: GET /transaction/list - Tranzaksiya yaratilgandan keyin ro'yxatni yangilash
                _statsBloc.add(
                  StatsGetTransactionsEvent(
                    walletId: _selectedWalletId!,
                    fromDate: fromDateStr,
                    toDate: toDateStr,
                  ),
                );

                // API: GET /wallet/balance - Tranzaksiya yaratilgandan keyin balansni yangilash
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
              print('👥 Data type: ${state.data.runtimeType}');

              if (state.data is List && (state.data as List).isNotEmpty) {
                print('👥 First item structure: ${(state.data as List)[0]}');
                // Har bir element strukturasini ko'rish
                for (int i = 0; i < (state.data as List).length && i < 3; i++) {
                  final item = (state.data as List)[i];
                  print(
                    '👥 Item $i keys: ${item is Map ? item.keys.toList() : 'Not a map'}',
                  );
                  if (item is Map) {
                    print('👥 Item $i values: ${item.toString()}');
                  }
                }
              }

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

              // API: GET /debtor-creditor/list - Yangilangan qarzkorlar ro'yxati (1 soniyadan keyin)
              Future.delayed(const Duration(seconds: 1), () {
                _statsBloc.add(const StatsGetDebtorsCreditors());
              });
            } else if (state is StatsTransactionDebtCreated) {
              // Qarz operatsiyasi yaratilganda
              print('💰 Transaction debt created: ${state.data}');
              print('💰 Full debt transaction response: ${state.toString()}');

              // Loading holatini o'chirish
              if (mounted) {
                setState(() {
                  _isCreatingDebtTransaction = false;
                });
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );

              // API: GET /debtor-creditor/list - Qarz yaratilgandan keyin ro'yxatni yangilash
              print('🔄 Debt transaction completed, reloading debtors...');

              // 1 soniya kutib qayta yuklash (API update uchun vaqt)
              Future.delayed(const Duration(seconds: 1), () {
                print('🔄 Reloading debtors after debt transaction...');
                _statsBloc.add(const StatsGetDebtorsCreditors());
              });

              print('🔄 Reloading debtors list after debt transaction...');

              // Tranzaksiyalar ro'yxatini yangilash
              if (_selectedWalletId != null) {
                final now = DateTime.now();
                final fromDate = DateTime(now.year, now.month, 1);
                final toDate = DateTime(now.year, now.month + 1, 0);

                final fromDateStr =
                    '${fromDate.day.toString().padLeft(2, '0')}.${fromDate.month.toString().padLeft(2, '0')}.${fromDate.year}';
                final toDateStr =
                    '${toDate.day.toString().padLeft(2, '0')}.${toDate.month.toString().padLeft(2, '0')}.${toDate.year}';

                // API: GET /transaction/list - Qarz tranzaksiyasidan keyin ro'yxatni yangilash
                _statsBloc.add(
                  StatsGetTransactionsEvent(
                    walletId: _selectedWalletId!,
                    fromDate: fromDateStr,
                    toDate: toDateStr,
                  ),
                );

                // API: GET /wallet/balance - Qarz tranzaksiyasidan keyin balansni yangilash
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
            } else if (state is StatsTransactionDeleted) {
              // Tranzaksiya o'chirilganda
              print('🗑️ Transaction deleted successfully');

              if (mounted) {
                setState(() {
                  _deletingTransactionIds.clear(); // Barcha IDlarni tozalash
                });
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );

              // Tranzaksiyalarni qayta yuklash
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
                
                // Balansni ham yangilash
                _statsBloc.add(
                  StatsGetWalletBalanceEvent(
                    walletId: _selectedWalletId!,
                    fromDate: fromDateStr,
                    toDate: toDateStr,
                  ),
                );
              }
            } else if (state is StatsError) {
              print('❌ StatsError received: ${state.message}');
              
              if (mounted) {
                setState(() {
                  _deletingTransactionIds.clear(); // Xatolikda ham tozalash
                  _isCreatingTransaction = false;
                  _isCreatingDebtTransaction = false;
                  _isCreatingConversion = false;
                });
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 2),
                ),
              );
            } else {
              // Boshqa state'lar uchun umumiy log
              print('🔄 Other state received: ${state.runtimeType} - $state');
            }
          },
          child: StatefulBuilder(
            builder: (context, setStateSB) {
              return BlocBuilder<StatsBloc, StatsState>(
                bloc: _statsBloc,
                builder: (context, blocState) {
                  final isLoading = blocState is StatsLoading;
                  
                  return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Column(
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
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Kurs ma'lumoti (ramkasiz)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Icon(Icons.currency_exchange,
                              //      color: Colors.blue.shade700,
                              //      size: 16),
                              // const SizedBox(width: 6),
                              Text(
                                'Kurs',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(width: 4),

                          Text(
                            '1 USD = ${_exchangeRate.toStringAsFixed(0)} UZS',
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Modern dizaynli tugmalar
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // Kirim tugmasi
                              GestureDetector(
                                onTap: () {
                                  setStateSB(() {
                                    type = TransactionType.income;
                                    debtType = ''; // qarz holatini reset qilish
                                    clearFormData(); // Form ma'lumotlarini tozalash
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient:
                                        type == TransactionType.income &&
                                            debtType.isEmpty
                                        ? LinearGradient(
                                            colors: [
                                              Colors.green.shade400,
                                              Colors.green.shade600,
                                            ],
                                          )
                                        : null,
                                    color:
                                        type == TransactionType.income &&
                                            debtType.isEmpty
                                        ? null
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow:
                                        type == TransactionType.income &&
                                            debtType.isEmpty
                                        ? [
                                            BoxShadow(
                                              color: Colors.green.shade300,
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : null,
                                    border: Border.all(
                                      color:
                                          type == TransactionType.income &&
                                              debtType.isEmpty
                                          ? Colors.transparent
                                          : Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.arrow_downward,
                                        size: 20,
                                        color:
                                            type == TransactionType.income &&
                                                debtType.isEmpty
                                            ? Colors.white
                                            : Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Kirim',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              type == TransactionType.income &&
                                                  debtType.isEmpty
                                              ? Colors.white
                                              : Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Chiqim tugmasi
                              GestureDetector(
                                onTap: () {
                                  setStateSB(() {
                                    type = TransactionType.expense;
                                    debtType = ''; // qarz holatini reset qilish
                                    clearFormData(); // Form ma'lumotlarini tozalash
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient:
                                        type == TransactionType.expense &&
                                            debtType.isEmpty
                                        ? LinearGradient(
                                            colors: [
                                              Colors.red.shade400,
                                              Colors.red.shade600,
                                            ],
                                          )
                                        : null,
                                    color:
                                        type == TransactionType.expense &&
                                            debtType.isEmpty
                                        ? null
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow:
                                        type == TransactionType.expense &&
                                            debtType.isEmpty
                                        ? [
                                            BoxShadow(
                                              color: Colors.red.shade300,
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : null,
                                    border: Border.all(
                                      color:
                                          type == TransactionType.expense &&
                                              debtType.isEmpty
                                          ? Colors.transparent
                                          : Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.arrow_upward,
                                        size: 20,
                                        color:
                                            type == TransactionType.expense &&
                                                debtType.isEmpty
                                            ? Colors.white
                                            : Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Chiqim',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              type == TransactionType.expense &&
                                                  debtType.isEmpty
                                              ? Colors.white
                                              : Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Qarz pul olish tugmasi
                              GestureDetector(
                                onTap: () {
                                  setStateSB(() {
                                    debtType = 'qarz_olish';
                                    clearFormData(); // Form ma'lumotlarini tozalash
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: debtType == 'qarz_olish'
                                        ? LinearGradient(
                                            colors: [
                                              Colors.blue.shade400,
                                              Colors.blue.shade600,
                                            ],
                                          )
                                        : null,
                                    color: debtType == 'qarz_olish'
                                        ? null
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: debtType == 'qarz_olish'
                                        ? [
                                            BoxShadow(
                                              color: Colors.blue.shade300,
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : null,
                                    border: Border.all(
                                      color: debtType == 'qarz_olish'
                                          ? Colors.transparent
                                          : Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.request_page,
                                        size: 20,
                                        color: debtType == 'qarz_olish'
                                            ? Colors.white
                                            : Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Qarz pul olish',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: debtType == 'qarz_olish'
                                              ? Colors.white
                                              : Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Qarz berish tugmasi
                              GestureDetector(
                                onTap: () {
                                  setStateSB(() {
                                    debtType = 'qarz_berish';
                                    clearFormData(); // Form ma'lumotlarini tozalash
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: debtType == 'qarz_berish'
                                        ? LinearGradient(
                                            colors: [
                                              Colors.orange.shade400,
                                              Colors.orange.shade600,
                                            ],
                                          )
                                        : null,
                                    color: debtType == 'qarz_berish'
                                        ? null
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: debtType == 'qarz_berish'
                                        ? [
                                            BoxShadow(
                                              color: Colors.orange.shade300,
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : null,
                                    border: Border.all(
                                      color: debtType == 'qarz_berish'
                                          ? Colors.transparent
                                          : Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.send,
                                        size: 20,
                                        color: debtType == 'qarz_berish'
                                            ? Colors.white
                                            : Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Qarz pul berish',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: debtType == 'qarz_berish'
                                              ? Colors.white
                                              : Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Konvertatsiya tugmasi
                              GestureDetector(
                                onTap: () async {
                                  // Avval walletlarni yuklash
                                  print('🔄 Loading wallets for konvertatsiya...');
                                  await _loadWalletsList();
                                  print('✅ Wallets loaded: ${_walletsList.length} items');
                                  
                                  // Keyin konvertatsiya rejimini yoqish
                                  setStateSB(() {
                                    debtType = 'konvertatsiya';
                                    clearFormData(); // Form ma'lumotlarini tozalash
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: debtType == 'konvertatsiya'
                                        ? LinearGradient(
                                            colors: [
                                              Colors.amber.shade400,
                                              Colors.amber.shade600,
                                            ],
                                          )
                                        : null,
                                    color: debtType == 'konvertatsiya'
                                        ? null
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: debtType == 'konvertatsiya'
                                        ? [
                                            BoxShadow(
                                              color: Colors.amber.shade300,
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : null,
                                    border: Border.all(
                                      color: debtType == 'konvertatsiya'
                                          ? Colors.transparent
                                          : Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.swap_horiz,
                                        size: 20,
                                        color: debtType == 'konvertatsiya'
                                            ? Colors.white
                                            : Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Konvertatsiya',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: debtType == 'konvertatsiya'
                                              ? Colors.white
                                              : Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                                  selectedCategory = TransactionCategory.other;
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        // Wallet Chiqim (Qayerdan)
                        const Text(
                          'Qayerdan (Chiqim Hamyoni):',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: DropdownButton<String>(
                            value: selectedWalletChiqimId,
                            hint: const Text('Hamyon tanlang'),
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: _walletsList.map((wallet) {
                              print(
                                '🏦 Chiqim wallet available: ${wallet['name']} (${wallet['currency']}) - ${wallet['walletId']}',
                              );
                              return DropdownMenuItem<String>(
                                value: wallet['walletId'],
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    '${wallet['name']} (${wallet['currency']}) - ${_formatWalletBalance(wallet['balance'], wallet['currency'])}',
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setStateSB(() {
                                selectedWalletChiqimId = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Wallet Kirim (Qayerga)
                        const Text(
                          'Qayerga (Kirim Hamyoni):',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: DropdownButton<String>(
                            value: selectedWalletKirimId,
                            hint: const Text('Hamyon tanlang'),
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: _walletsList.map((wallet) {
                              print(
                                '🏦 Kirim wallet available: ${wallet['name']} (${wallet['currency']}) - ${wallet['walletId']}',
                              );
                              return DropdownMenuItem<String>(
                                value: wallet['walletId'],
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    '${wallet['name']} (${wallet['currency']}) - ${_formatWalletBalance(wallet['balance'], wallet['currency'])}',
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setStateSB(() {
                                selectedWalletKirimId = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Chiqim suma
                        TextField(
                          controller: chiqimAmountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            DecimalNumberTextFormatter(),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Chiqim summasi',
                            border: OutlineInputBorder(),
                            hintText: 'Qancha chiqadi', //uu
                          ),
                          onChanged: (value) {
                            // Formatlangan textdan raqamni olish
                            double numericValue =
                                NumberFormatterHelper.parseFormattedNumber(
                                  value,
                                );
                            print(
                              'DEBUG: Chiqim onChanged - formatted: "$value", numeric: $numericValue',
                            );

                            _calculateConversionAmount(
                              numericValue.toString(),
                              chiqimAmountCtrl,
                              kirimAmountCtrl,
                              selectedWalletChiqimId,
                              selectedWalletKirimId,
                              true, // true = chiqim o'zgardi
                              setStateSB,
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        // Kirim suma
                        TextField(
                          controller: kirimAmountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            DecimalNumberTextFormatter(),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Kirim summasi',
                            border: OutlineInputBorder(),
                            hintText: 'Qancha kiradi',
                          ),
                          onChanged: (value) {
                            // Formatlangan textdan raqamni olish
                            double numericValue =
                                NumberFormatterHelper.parseFormattedNumber(
                                  value,
                                );
                            print(
                              'DEBUG: Kirim onChanged - formatted: "$value", numeric: $numericValue',
                            );

                            _calculateConversionAmount(
                              numericValue.toString(),
                              chiqimAmountCtrl,
                              kirimAmountCtrl,
                              selectedWalletChiqimId,
                              selectedWalletKirimId,
                              false, // false = kirim o'zgardi
                              setStateSB,
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        // Izoh (konvertatsiya uchun) - oxirida
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
                            // API: GET /debtor-creditor/list - Dialog ochishdan oldin ro'yxatni yangilash
                            print(
                              '🔄 Refreshing debtors list before showing dialog...',
                            );
                            _statsBloc.add(const StatsGetDebtorsCreditors());

                            // Biroz kutib, dialogni ochish
                            Future.delayed(
                              const Duration(milliseconds: 300),
                              () {
                                _showDebtorsDialog(
                                  context,
                                  debtType,
                                  debtPersonCtrl,
                                  setStateSB,
                                  (id) => selectedPersonId = id,
                                );
                              },
                            );
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
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            DecimalNumberTextFormatter(),
                          ],
                          onChanged: (value) {
                            setStateSB(() {
                              // Hamyon valyutasini hisobga olish
                              final walletCurrency =
                                  widget.walletCurrency?.toUpperCase() ?? 'UZS';

                              if (value.isNotEmpty) {
                                final cleanAmount =
                                    value.replaceAll(' ', '').replaceAll(',', '');
                                final numericAmount =
                                    double.tryParse(cleanAmount) ?? 0;

                                if (walletCurrency == 'USD') {
                                  // USD hamyon
                                  if (selectedCurrency == 'UZS') {
                                    // USD summani UZS ko'rinishda
                                    final convertedAmount =
                                        numericAmount * _exchangeRate;
                                    displayedAmount =
                                        _formatNumber(convertedAmount.toInt());
                                  } else {
                                    // USD summani USD ko'rinishda
                                    displayedAmount = value;
                                  }
                                } else {
                                  // UZS hamyon
                                  if (selectedCurrency == 'USD') {
                                    // UZS summani USD ko'rinishda
                                    final convertedAmount =
                                        numericAmount / _exchangeRate;
                                    displayedAmount =
                                        convertedAmount.toStringAsFixed(2);
                                  } else {
                                    // UZS summani UZS ko'rinishda
                                    displayedAmount = value;
                                  }
                                }
                              } else {
                                displayedAmount = '0';
                              }
                            });
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
                                constraints: const BoxConstraints(
                                  minHeight: 56,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Suma qarz:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      displayedAmount.isNotEmpty &&
                                              displayedAmount != '0'
                                          ? _formatDisplayAmount(
                                              displayedAmount,
                                              selectedCurrency,
                                            )
                                          : '0 $selectedCurrency',
                                      style: TextStyle(
                                        fontSize: _getAdaptiveFontSize(
                                          displayedAmount,
                                          selectedCurrency,
                                        ),
                                        fontWeight: FontWeight.bold,
                                        color: selectedCurrency == 'USD'
                                            ? Colors.green[700]
                                            : Colors.blue[700],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      softWrap: true,
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
                                      // Hamyon valyutasini hisobga olish
                                      final walletCurrency =
                                          widget.walletCurrency
                                              ?.toUpperCase() ??
                                          'UZS';

                                      if (amountCtrl.text.isNotEmpty &&
                                          value != selectedCurrency) {
                                        final cleanAmount = amountCtrl.text
                                            .replaceAll(' ', '')
                                            .replaceAll(',', '');
                                        final numericAmount =
                                            double.tryParse(cleanAmount) ?? 0;

                                        if (walletCurrency == 'USD') {
                                          // USD hamyon
                                          if (value == 'UZS') {
                                            // USD summani UZS ko'rinishda
                                            final convertedAmount =
                                                numericAmount * _exchangeRate;
                                            displayedAmount = _formatNumber(
                                              convertedAmount.toInt(),
                                            );
                                          } else {
                                            // USD summani USD ko'rinishda
                                            displayedAmount = amountCtrl.text;
                                          }
                                        } else {
                                          // UZS hamyon
                                          if (value == 'USD') {
                                            // UZS summani USD ko'rinishda
                                            final convertedAmount =
                                                numericAmount / _exchangeRate;
                                            displayedAmount = convertedAmount
                                                .toStringAsFixed(2);
                                          } else {
                                            // UZS summani UZS ko'rinishda
                                            displayedAmount = amountCtrl.text;
                                          }
                                        }
                                      } else if (amountCtrl.text.isEmpty) {
                                        displayedAmount = '0';
                                      }
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
                      // Summa kiritish (faqat oddiy tranzaksiyalar uchun)
                      if (debtType.isEmpty)
                        TextField(
                          controller: amountCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Summa',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            DecimalNumberTextFormatter(),
                          ],
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

                      // Qarz pul olish uchun checkbox (balansga ta'sir qilmaslik uchun)
                      if (debtType == 'qarz_olish')
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                // Faqat checkbox OFF holatida bo'lsa (ya'ni ON qilyapmiz) dialog ko'rsatish
                                if (isBalanceAffected) {
                                  // Dialog ko'rsatish - ON qilyapmiz
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
                                } else {
                                  // Checkbox OFF qilyapmiz - dialog yo'q
                                  setStateSB(() {
                                    isBalanceAffected = !isBalanceAffected;
                                  });
                                }
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
                                // Faqat checkbox OFF holatida bo'lsa (ya'ni ON qilyapmiz) dialog ko'rsatish
                                if (isBalanceAffected) {
                                  // Dialog ko'rsatish - ON qilyapmiz
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
                                } else {
                                  // Checkbox OFF qilyapmiz - dialog yo'q
                                  setStateSB(() {
                                    isBalanceAffected = !isBalanceAffected;
                                  });
                                }
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
                            onPressed: isLoading
                                ? null
                                : () async {
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

                              // Umumiy summa validatsiyasi (faqat konvertatsiya emas)
                              if (debtType != 'konvertatsiya' && amount <= 0) {
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

                                // Izohni tekshirish (bo'sh bo'lmasligi kerak)
                                if (comment.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Iltimos, izoh yozing!',
                                      ),
                                      duration: Duration(seconds: 2),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }

                                // Qarz operatsiyasi API'si
                                double debtAmount = 0.0;
                                try {
                                  debtAmount = double.parse(
                                    displayedAmount
                                        .replaceAll(' ', '')
                                        .replaceAll(',', ''),
                                  );
                                } catch (e) {
                                  print(
                                    'Qarz miqdorini parse qilishda xatolik: $e',
                                  );
                                }

                                print('🎯 Debt Transaction Debug:');
                                print('   - amount (main): $amount');
                                print(
                                  '   - debtAmount (SumaQarz): $debtAmount',
                                );
                                print(
                                  '   - selectedCurrency: $selectedCurrency',
                                );
                                print(
                                  '   - displayedAmount: "$displayedAmount"',
                                );

                                // Loading holatini o'rnatish
                                setState(() {
                                  _isCreatingDebtTransaction = true;
                                });

                                // API: POST /transaction/debt/create - Qarz berish/olish tranzaksiyasi yaratish
                                _statsBloc.add(
                                  StatsCreateTransactionDebt(
                                    type: debtType == 'qarz_berish'
                                        ? 'qarzPulBerish'
                                        : 'qarzPulOlish',
                                    walletId: _selectedWalletId!,
                                    debtorCreditorId: selectedPersonId!,
                                    previousDebt:
                                        !isBalanceAffected, // Checkbox bosilsa true bo'ladi
                                    currency: selectedCurrency.toLowerCase(),
                                    amount: amount,
                                    amountDebt: debtAmount,
                                    comment: comment.isNotEmpty
                                        ? comment
                                        : null,
                                  ),
                                );
                              } else if (debtType == 'konvertatsiya') {
                                // Konvertatsiya operatsiyasi uchun
                                if (selectedWalletChiqimId == null ||
                                    selectedWalletChiqimId!.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Chiqim hamyonini tanlang!',
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }

                                if (selectedWalletKirimId == null ||
                                    selectedWalletKirimId!.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Kirim hamyonini tanlang!'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }

                                if (selectedWalletChiqimId ==
                                    selectedWalletKirimId) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Bir xil hamyon tanlash mumkin emas!',
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }

                                // Chiqim va kirim summalarini tekshirish
                                final chiqimAmountText = chiqimAmountCtrl.text
                                    .trim()
                                    .replaceAll(' ', '');
                                final kirimAmountText = kirimAmountCtrl.text
                                    .trim()
                                    .replaceAll(' ', '');

                                if (chiqimAmountText.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Chiqim summasini kiriting!',
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }

                                if (kirimAmountText.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Kirim summasini kiriting!',
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }

                                final chiqimAmount = double.tryParse(
                                  chiqimAmountText,
                                );
                                final kirimAmount = double.tryParse(
                                  kirimAmountText,
                                );

                                if (chiqimAmount == null || chiqimAmount <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Chiqim summasini to\'g\'ri kiriting!',
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }

                                if (kirimAmount == null || kirimAmount <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Kirim summasini to\'g\'ri kiriting!',
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }

                                // Izoh majburiy tekshirish
                                if (comment.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Izoh yozish majburiy!'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }

                                print('💱 DEBUG: Chiqim amount: $chiqimAmount');
                                print('💱 DEBUG: Kirim amount: $kirimAmount');
                                print(
                                  '💱 DEBUG: WalletIdChiqim: $selectedWalletChiqimId',
                                );
                                print(
                                  '💱 DEBUG: WalletIdKirim: $selectedWalletKirimId',
                                );

                                // Loading holatini o'rnatish
                                setState(() {
                                  _isCreatingConversion = true;
                                });

                                // Konvertatsiya API call
                                // API: POST /transaction/conversion/create - Konvertatsiya tranzaksiyasi yaratish
                                _statsBloc.add(
                                  StatsCreateTransactionConversion(
                                    walletIdChiqim: selectedWalletChiqimId!,
                                    walletIdKirim: selectedWalletKirimId!,
                                    amountChiqim: chiqimAmount,
                                    amountKirim: kirimAmount,
                                    comment: comment,
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

                                // Loading holatini o'rnatish
                                setState(() {
                                  _isCreatingTransaction = true;
                                });

                                // API: POST /transaction/create - Oddiy kirim/chiqim tranzaksiyasi yaratish
                                _statsBloc.add(
                                  StatsCreateTransactionEvent(
                                    walletId: _selectedWalletId!,
                                    transactionTypesId: transactionTypesId,
                                    type: apiType,
                                    comment: comment,
                                    amount: amount,
                                    currency: 'UZS',
                                    exchangeRate:
                                        _exchangeRate, // Joriy kursni saqlash
                                  ),
                                );
                              }

                              // Dialog yopish - commented out, listener da yopiladi
                              // if (mounted) {
                              //   Navigator.of(dialogCtx).pop();
                              // }
                            },
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('OK'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              );
                },
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
    // Fullscreen navigation bilan ochish
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (navigationContext) => _buildEditTransactionDialog(t),
      ),
    );
  }

  Widget _buildEditTransactionDialog(Transaction t) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tranzaksiyani tahrirlash'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildEditTransactionDialogContent(t),
    );
  }

  Widget _buildEditTransactionDialogContent(Transaction t) {
    return Builder(
      builder: (dialogCtx) {
        TransactionType type = t.type;
        final titleCtrl = TextEditingController(text: t.title);
        final amountCtrl = TextEditingController(text: t.amount.toString());

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            StatefulBuilder(
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
                          onSelected: (v) =>
                              setStateSB(() => type = TransactionType.expense),
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
                      decoration: const InputDecoration(labelText: 'Sarlavha'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountCtrl,
                      decoration: const InputDecoration(labelText: 'Summа'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
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
          ],
        );
      },
    );
  } //shu royhatni dizaynlari hama qismi shu yerda

  @override
  Widget build(BuildContext context) {
    // simplified stats view uses wallet balance and recent transactions

    return BlocProvider<StatsBloc>.value(
      value: _statsBloc,
      child: BlocListener<StatsBloc, StatsState>(
        listener: (context, state) {
          print(
            '🔔 BlocListener received state: ${state.runtimeType} - $state',
          );

          if (state is StatsTransactionCreatedSuccess) {
            print('✅ Transaction created success: ${state.message}');

            // API: GET /debtor-creditor/list - Tranzaksiya muvaffaqiyatli yaratilgandan keyin yangilash
            Future.delayed(const Duration(seconds: 1), () {
              print('🔄 Reloading debtors after transaction...');
              _statsBloc.add(const StatsGetDebtorsCreditors());
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            ); // Tranzaksiya yaratilgandan keyin ro'yxatni yangilash
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
            print('❌ StatsError received: ${state.message}');

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
        } else if (state is StatsTransactionDeleted) {
          // Tranzaksiya o'chirildi - ma'lumotlarni qayta yuklash
          print('✅ Transaction deleted successfully!');
          
          // Loading holatini tozalash
          if (mounted) {
            setState(() {
              _deletingTransactionIds.clear();
            });
          }
          
          // Success xabari
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          
          // Tranzaksiyalar va balansni qayta yuklash
          if (_selectedWalletId != null) {
            final now = DateTime.now();
            final fromDate = DateTime(now.year, now.month, 1);
            final toDate = DateTime(now.year, now.month + 1, 0);

            final fromDateStr =
                '${fromDate.day.toString().padLeft(2, '0')}.${fromDate.month.toString().padLeft(2, '0')}.${fromDate.year}';
            final toDateStr =
                '${toDate.day.toString().padLeft(2, '0')}.${toDate.month.toString().padLeft(2, '0')}.${toDate.year}';

            // Tranzaksiyalarni qayta yuklash
            _statsBloc.add(
              StatsGetTransactionsEvent(
                walletId: _selectedWalletId!,
                fromDate: fromDateStr,
                toDate: toDateStr,
              ),
            );

            // Balansni qayta yuklash
            _statsBloc.add(
              StatsGetWalletBalanceEvent(
                walletId: _selectedWalletId!,
                fromDate: fromDateStr,
                toDate: toDateStr,
              ),
            );
          }
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

              // API: GET /transaction/list - Pull-to-refresh orqali tranzaksiyalarni yangilash
              _statsBloc.add(
                StatsGetTransactionsEvent(
                  walletId: _selectedWalletId!,
                  fromDate: fromDateStr,
                  toDate: toDateStr,
                ),
              );

              // API: GET /wallet/balance - Pull-to-refresh orqali balansni yangilash
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
                                      ? _formatWalletBalanceDisplay(
                                          _currentWalletBalance,
                                        )
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
                                      ? _formatStatAmount(_chiqimTotal)
                                      : _formatStatAmount(
                                          _calculateExpenseTotal(),
                                        ),
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
                                      ? _formatStatAmount(_kirimTotal)
                                      : _formatStatAmount(
                                          _calculateIncomeTotal(),
                                        ),
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
                            // Yashil: income (kirim), loanTaken (qarz pul olish)
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
                                        // Kurs ma'lumoti (faqat tranzaksiya paytdagi saqlangan kurs)
                                        if (t.exchangeRate != null)
                                          Text(
                                            'Kurs: 1 USD = ${t.exchangeRate!.toStringAsFixed(0)} UZS ',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
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
                                        // Qarz pul olish/berish uchun maxsus ko'rinish
                                        else if (t.type ==
                                                TransactionType.loanTaken ||
                                            t.type ==
                                                TransactionType.loanGiven) ...[
                                          // Qarz tranzaksiyalari uchun maxsus ko'rinish
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
                                          if (t.amountDebit != null &&
                                              t.amountDebit! > 0)
                                            Text(
                                              'Suma qarz: ${_formatDebtAmount(t.amountDebit!, t.paymentMethod ?? 'UZS')}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          const SizedBox(height: 4),
                                          // Avvalgi qarzim statusi
                                          Text(
                                            'Avvalgi qarzim: ${(t.openingBalance == true) ? 'Ha' : 'Yo\'q'}',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
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
                                        () {
                                          String displayText;
                                          if (_showBalance) {
                                            if (t.type ==
                                                TransactionType.conversion) {
                                              displayText =
                                                  _getConversionDisplayAmount(
                                                    t,
                                                  );
                                              print(
                                                '💰 DISPLAYING conversion for ID ${t.id.substring(0, 8)}: "$displayText"',
                                              );
                                            } else {
                                              displayText =
                                                  _formatTransactionAmount(
                                                    t.amount,
                                                  );
                                            }
                                          } else {
                                            displayText = '••••••';
                                          }
                                          return displayText;
                                        }(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      GestureDetector(
                                        onTap: () async {
                                          if (t.id == null || _deletingTransactionIds.contains(t.id)) return;
                                          
                                          // Tasdiqlash dialogi
                                          final confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('O\'chirish'),
                                              content: const Text(
                                                'Ushbu tranzaksiyani o\'chirishni xohlaysizmi?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(ctx).pop(false),
                                                  child: const Text('Yo\'q'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.of(ctx).pop(true),
                                                  child: const Text(
                                                    'Ha',
                                                    style: TextStyle(color: Colors.red),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirmed == true && !_deletingTransactionIds.contains(t.id)) {
                                            // Loading holatini o'rnatish
                                            setState(() {
                                              _deletingTransactionIds.add(t.id!);
                                            });
                                            
                                            print('🗑️ O\'chirilayotgan tranzaksiya ID: ${t.id}');
                                            
                                            // Faqat DELETE API ga murojaat qilish
                                            _statsBloc.add(
                                              StatsDeleteTransactionEvent(
                                                transactionId: t.id!,
                                              ),
                                            );
                                          }
                                        },
                                        child: _deletingTransactionIds.contains(t.id)
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.delete,
                                                color: Colors.white,
                                                size: 20,
                                              ),
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
          heroTag: 'add_transaction',
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

  String _formatNumberWithDecimal(double number) {
    // Kasr qismli raqamlarni formatlash
    // Agar kasr qism bor bo'lsa, ko'rsatadi
    print('📊 _formatNumberWithDecimal called with: $number');

    if (number == number.toInt()) {
      // Kasr qism yo'q, faqat butun qismni qaytarish
      final result = _formatNumber(number.toInt());
      print('   → No decimal part, returning: "$result"');
      return result;
    }

    // Kasr qism bor
    final integerPart = number.floor();
    final decimalPart = number - integerPart;

    // Kasr qismni 2 ta raqamgacha cheklash
    final decimalStr = (decimalPart).toStringAsFixed(2).substring(2);

    // Butun qismni formatlash
    final formattedInteger = _formatNumber(integerPart);

    final result = '$formattedInteger.$decimalStr';
    print('   → With decimal part, returning: "$result"');
    return result;
  }

  String _formatUSDAmount(double amount) {
    // USD miqdorini probel bilan formatlash
    final amountStr = amount.toStringAsFixed(2);
    final parts = amountStr.split('.');
    final integerPart = int.parse(parts[0]);
    final decimalPart = parts[1];

    final formattedInteger = _formatNumber(integerPart);
    return '$formattedInteger.$decimalPart';
  }

  String _formatDebtAmount(double amount, String currency) {
    // Debt amount formatting based on currency
    if (currency.toUpperCase() == 'USD') {
      // USD: show with space formatting and 2 decimal places
      return '${_formatUSDAmount(amount)} USD';
    } else {
      // UZS: show as integer with space formatting
      return '${_formatNumber(amount.toInt())} ${currency.toUpperCase()}';
    }
  }

  String _formatWalletBalance(double balance, String currency) {
    // Wallet balance formatting based on currency
    if (currency.toUpperCase() == 'USD' || currency.toUpperCase() == 'EUR') {
      // USD/EUR: show with space formatting and 2 decimal places
      return _formatUSDAmount(balance);
    } else {
      // UZS: show as integer with space formatting
      return _formatNumber(balance.toInt());
    }
  }

  String _formatStatAmount(double amount) {
    // Statistics amount formatting (Chiqim/Kirim) based on wallet currency
    final walletCurrency = widget.walletCurrency?.toUpperCase() ?? 'UZS';
    if (walletCurrency == 'USD') {
      return '${_formatUSDAmount(amount)} ${_getCurrencySymbol()}';
    } else {
      return '${_formatNumber(amount.toInt())} ${_getCurrencySymbol()}';
    }
  }

  String _formatWalletBalanceDisplay(double balance) {
    // Wallet balance display with currency symbol and proper formatting
    final walletCurrency = widget.walletCurrency?.toUpperCase() ?? 'UZS';
    if (walletCurrency == 'USD') {
      return '${_formatUSDAmount(balance)} ${_getCurrencySymbol()}';
    } else {
      return '${_formatNumber(balance.toInt())} ${_getCurrencySymbol()}';
    }
  }

  String _formatTransactionAmount(double amount) {
    // Transaction amount formatting based on wallet currency
    final walletCurrency = widget.walletCurrency?.toUpperCase() ?? 'UZS';
    if (walletCurrency == 'USD') {
      // USD wallet: show amount with space formatting and 2 decimal places
      return '\$${_formatUSDAmount(amount)}';
    } else {
      // UZS wallet: show amount with decimal if present, space formatting
      return '${_formatNumberWithDecimal(amount)} ${_getCurrencySymbol()}';
    }
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
          print('✅ Detected QARZ PUL OLISH - will be GREEN');
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
            typeString.contains('konvert') ||
            typeString == 'konvertatsiya' ||
            item['type']?.toString() == 'konvertatsiya') {
          type = TransactionType.conversion;
          print('✅ Detected CONVERSION - will be ORANGE');
          print(
            '🔍 Conversion data: walletKirim=${item['walletKirim']}, walletChiqim=${item['walletChiqim']}',
          );
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

        // Konvertatsiya uchun aniq summalar
        double? amountKirim;
        double? amountChiqim;

        if (type == TransactionType.conversion) {
          amountKirim = double.tryParse(item['amountKirim']?.toString() ?? '0');
          amountChiqim = double.tryParse(
            item['amountChiqim']?.toString() ?? '0',
          );
          print(
            '💱 Conversion amounts: chiqim=$amountChiqim, kirim=$amountKirim',
          );
        }

        // Qarz pul olish/berish uchun qo'shimcha ma'lumotlar
        final counterparty =
            item['counterparty']?.toString() ?? ''; // Kimdan/Kimga

        // amountDebit - qarz uchun debtAmount
        double amountDebit = 0.0;
        if (type == TransactionType.conversion) {
          // Konvertatsiya uchun amountDebit = amountChiqim
          amountDebit = amountChiqim ?? 0.0;
        } else {
          // Qarz uchun debt amount
          amountDebit =
              double.tryParse(item['debtAmount']?.toString() ?? '0') ??
              double.tryParse(item['amountdebit']?.toString() ?? '0') ??
              0.0;
        }

        // Kurs ma'lumoti (tranzaksiya qilingan paytdagi)
        // API dan "11 800" formatida keladi - probelni olib tashlaymiz
        final kursString = item['kurs']?.toString() ?? '';
        double? exchangeRate;
        if (kursString.isNotEmpty) {
          final cleanKurs = kursString
              .replaceAll(' ', '')
              .replaceAll(',', '')
              .replaceAll('.', '');
          exchangeRate = double.tryParse(cleanKurs);
        } else if (item['exchangeRate'] != null) {
          exchangeRate = double.tryParse(
            item['exchangeRate']?.toString() ?? '0',
          );
        }

        // Currency ma'lumoti
        final currency = item['currency']?.toString().toUpperCase() ?? 'UZS';

        print('🔍 Transaction ID: ${item['id']}');
        print(
          '💱 Raw API data: kurs="${item['kurs']}", exchangeRate="${item['exchangeRate']}"',
        );
        print(
          '💱 Parsed: kurs="$kursString", final exchangeRate=$exchangeRate',
        );
        print('💰 Transaction currency: $currency, debtAmount: $amountDebit');

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
          amountKirim: amountKirim, // Konvertatsiya kirim summasi
          amountChiqim: amountChiqim, // Konvertatsiya chiqim summasi
          openingBalance: item['openingBalance'] as bool?, // Avvalgi qarzim
          exchangeRate:
              exchangeRate ?? _exchangeRate, // API dan kelgan yoki joriy kurs
          paymentMethod: currency, // Currency'ni paymentMethod'da saqlaymiz
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

    print('🔍 OPENING TRANSACTION TYPE PICKER:');
    print('   transactionType: $transactionType');
    print('   apiType: $apiType');

    _isFetchingTransactionTypes = true;
    // API: GET /transaction-types/list - Tranzaksiya turlarini (kategoriyalarni) yuklash
    _statsBloc.add(StatsGetTransactionTypesEvent(type: apiType));

    // Fullscreen navigation bilan ochish
    Navigator.of(dialogContext)
        .push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (navigationContext) =>
                _buildTransactionTypePickerDialog(
                  navigationContext, 
                  apiType, 
                  onSelected,
                ),
          ),
        )
        .then((_) {
          _isFetchingTransactionTypes = false;
        });
  }

  Widget _buildTransactionTypePickerDialog(
    BuildContext pickerContext,
    String apiType,
    void Function(Map<String, String>) onSelected,
  ) {
    return WillPopScope(
      onWillPop: () async {
        // Telefon back tugmasi bosganida - faqat dialog yopiladi
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(apiType == 'kirim' ? 'Kirim turi' : 'Chiqim turi'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              // Dialog contextini yopish - faqat type picker oynasini yopadi
              Navigator.pop(pickerContext);
            },
          ),
        ),
        body: _buildTransactionTypePickerContent(pickerContext, apiType, onSelected),
      ),
    );
  }

  Widget _buildTransactionTypePickerContent(
    BuildContext pickerContext,
    String apiType,
    void Function(Map<String, String>) onSelected,
  ) {
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

            // API: GET /transaction-types/list - Yangi tur yaratilgandan keyin ro'yxatni yangilash
            _statsBloc.add(StatsGetTransactionTypesEvent(type: apiType));
          }
        },
        builder: (context, state) {
          print('🎨 BUILDER CALLED: state type = ${state.runtimeType}');

          final searchCtrl = TextEditingController();
          String searchQuery = '';

          Widget buildLoading([String? text]) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(text ?? 'Turlar yuklanmoqda...'),
              ],
            ),
          );

          if (state is StatsLoading) {
            print('   → Showing loading...');
            return buildLoading();
          } else if (state is StatsTransactionTypesLoaded) {
            print('   → Data loaded, normalizing...');
            final allItems = _normalizeTransactionTypeList(state.data, apiType);
            print('   → Normalized items count: ${allItems.length}');
            print('   → Expected apiType: $apiType');
            
            // Debug: Birinchi 3 ta elementni ko'rsatish
            if (allItems.isNotEmpty) {
              for (int i = 0; i < (allItems.length > 3 ? 3 : allItems.length); i++) {
                print('   → Item $i: name="${allItems[i]['name']}", type="${allItems[i]['type']}"');
              }
            }

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

                return RefreshIndicator(
                  onRefresh: () async {
                    // API: GET /transaction-types/list - Pull to refresh
                    _statsBloc.add(StatsGetTransactionTypesEvent(type: apiType));
                    
                    // 1 soniya kutamiz
                    await Future.delayed(const Duration(seconds: 1));
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                    // Search field va Add button qatori
                    Row(
                      children: [
                        // Search field
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFf9fafb),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFd1d5db),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: searchCtrl,
                              onChanged: (value) {
                                setDialogState(() {
                                  searchQuery = value;
                                });
                              },
                              decoration: const InputDecoration(
                                hintText: 'Qidirish...',
                                hintStyle: TextStyle(
                                  color: Color(0xFF9ca3af),
                                  fontSize: 14,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Color(0xFF9ca3af),
                                  size: 18,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Add button
                        Material(
                          color: const Color(0xFF10b981),
                          borderRadius: BorderRadius.circular(8),
                          elevation: 2,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              _showCreateTypeDialogInline(
                                apiType,
                                setDialogState,
                              );
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Items list
                    if (items.isEmpty)
                      Column(
                        children: [
                          const SizedBox(height: 40),
                          Text(
                            searchQuery.isEmpty
                                ? 'Turlar topilmadi'
                                : 'Hech narsa topilmadi',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6b7280),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 4),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final displayName = item['name'] ?? 'Noma\'lum';

                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      onSelected(item);
                                      Navigator.pop(pickerContext);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFf9fafb),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFd1d5db),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              displayName,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF374151),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          } else if (state is StatsError) {
            print('   → Error state: ${state.message}');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.message,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Yopish'),
                    ),
                  ],
                ),
              ),
            );
          }

          print('   → Unknown state, showing default loading...');
          return buildLoading('Yuklanmoqda...');
        },
      ),
    );
  }

  Future<void> _showCreateTypeDialogInline(
    String apiType,
    StateSetter setDialogState,
  ) async {
    final nameCtrl = TextEditingController();
    await showDialog(
      context: context,
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
              // API: POST /transaction-types/create - Yangi tranzaksiya turi (kategoriya) yaratish
              _statsBloc.add(
                StatsCreateTransactionTypeEvent(name: name, type: apiType),
              );
              Navigator.of(ctx).pop();
            },
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
  }
  // Deprecated - use _openTransactionTypePicker instead
  /*
  void _openTransactionTypePickerOld({
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

                    final Widget addButton = Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Material(
                        color: const Color(0xFF10b981),
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: showCreateTypeDialog,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Text(
                              apiType == 'kirim'
                                  ? 'Yangi kirim turi qo\'shish'
                                  : 'Yangi chiqim turi qo\'shish',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
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
                                  const SizedBox(height: 4),
                              itemBuilder: (context, index) {
                                final item = items[index];
                                final displayName = item['name'] ?? 'Noma\'lum';

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () {
                                        Navigator.of(pickerCtx).pop();
                                        onSelected(item);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFf9fafb),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(0xFFd1d5db),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                displayName,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF374151),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
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
  */

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

  double _getAdaptiveFontSize(String amount, String currency) {
    // Matn uzunligiga qarab font size'ni moslash
    final fullText = '$amount $currency';
    final textLength = fullText.length;

    if (textLength <= 12) {
      return 16.0; // Normal size
    } else if (textLength <= 18) {
      return 14.0; // Kichikroq
    } else if (textLength <= 25) {
      return 12.0; // Yanada kichik
    } else {
      return 10.0; // Eng kichik
    }
  }

  String _formatDisplayAmount(String amount, String currency) {
    // Juda uzun bo'lsa, qisqartirish
    final fullText = '$amount $currency';
    if (fullText.length > 30) {
      // Raqamni qisqartirish
      if (amount.length > 20) {
        final shortAmount = '${amount.substring(0, 15)}...';
        return '$shortAmount $currency';
      }
    }
    return fullText;
  }

  // Konvertatsiya uchun summa ko'rsatish
  String _getConversionDisplayAmount(Transaction t) {
    print('DEBUG CONVERSION: Transaction ID: ${t.id}');
    print('DEBUG CONVERSION: amount: ${t.amount}');
    print('DEBUG CONVERSION: amountDebit: ${t.amountDebit}');
    print('DEBUG CONVERSION: amountKirim: ${t.amountKirim}');
    print('DEBUG CONVERSION: amountChiqim: ${t.amountChiqim}');
    print('DEBUG CONVERSION: walletChiqim: ${t.walletChiqim}');
    print('DEBUG CONVERSION: walletKirim: ${t.walletKirim}');
    print('DEBUG CONVERSION: title: ${t.title}');
    print('DEBUG CONVERSION: currentWalletCurrency: ${widget.walletCurrency}');

    // Current wallet currency detection
    final currentWalletCurrency = widget.walletCurrency?.toUpperCase() ?? 'UZS';

    // Wallet currency detection - _walletsList dan topish
    final chiqimWalletName = t.walletChiqim ?? '';
    final kirimWalletName = t.walletKirim ?? '';

    print('🔍 WALLET DETECTION:');
    print('   chiqimWalletName: "$chiqimWalletName"');
    print('   kirimWalletName: "$kirimWalletName"');

    // Wallet listidan to'g'ri currency ni topish - 'name' va 'walletName' ikkalasini ham tekshirish
    final chiqimWalletData = _walletsList.firstWhere(
      (w) => 
          w['walletName']?.toString() == chiqimWalletName ||
          w['name']?.toString() == chiqimWalletName,
      orElse: () => <String, dynamic>{},
    );
    final kirimWalletData = _walletsList.firstWhere(
      (w) => 
          w['walletName']?.toString() == kirimWalletName ||
          w['name']?.toString() == kirimWalletName,
      orElse: () => <String, dynamic>{},
    );

    final chiqimCurrency =
        chiqimWalletData['currency']?.toString().toUpperCase() ?? 'UZS';
    final kirimCurrency =
        kirimWalletData['currency']?.toString().toUpperCase() ?? 'UZS';

    bool isChiqimUSD = chiqimCurrency == 'USD';
    bool isKirimUSD = kirimCurrency == 'USD';

    print('   chiqimWalletData: $chiqimWalletData');
    print('   kirimWalletData: $kirimWalletData');
    print('   chiqimCurrency: $chiqimCurrency (isUSD: $isChiqimUSD)');
    print('   kirimCurrency: $kirimCurrency (isUSD: $isKirimUSD)');
    print('   currentWalletCurrency: $currentWalletCurrency');

    // BIRINCHI: API'dan to'g'ridan-to'g'ri amountKirim va amountChiqim ishlatish
    if (t.amountKirim != null &&
        t.amountKirim! > 0 &&
        t.amountChiqim != null &&
        t.amountChiqim! > 0) {
      print(
        '✅ Using API amounts: chiqim=${t.amountChiqim}, kirim=${t.amountKirim}',
      );

      // Current hamyonga qarab to'g'ri summani ko'rsatish
      if (currentWalletCurrency == 'USD') {
        // USD hamyonida - USD summani ko'rsatish
        if (isChiqimUSD) {
          // USD chiqim - chiqim summasini ko'rsatish (USD → UZS konvertatsiya)
          print('   → USD wallet, USD chiqim: showing amountChiqim');
          return '\$${_formatUSDAmount(t.amountChiqim!)}';
        } else if (isKirimUSD) {
          // USD kirim - kirim summasini ko'rsatish (UZS → USD konvertatsiya)
          print('   → USD wallet, USD kirim: showing amountKirim');
          return '\$${_formatUSDAmount(t.amountKirim!)}';
        } else {
          // Wallet topilmadi, lekin USD hamyonida - eng kichik qiymatni ko'rsatish
          print('   → USD wallet, wallets not found: using smaller amount');
          final smallerAmount = t.amountChiqim! < t.amountKirim! 
              ? t.amountChiqim! 
              : t.amountKirim!;
          return '\$${_formatUSDAmount(smallerAmount)}';
        }
      } else {
        // UZS hamyonida - UZS summani ko'rsatish
        if (isKirimUSD) {
          // USD kirim, UZS chiqim - chiqim summasini ko'rsatish (UZS → USD konvertatsiya)
          print('   → UZS wallet, USD kirim: showing amountChiqim');
          return '${_formatNumberWithDecimal(t.amountChiqim!)} som';
        } else if (isChiqimUSD) {
          // USD chiqim, UZS kirim - kirim summasini ko'rsatish (USD → UZS konvertatsiya)
          print('   → UZS wallet, USD chiqim: showing amountKirim');
          return '${_formatNumberWithDecimal(t.amountKirim!)} som';
        } else {
          // Wallet topilmadi, lekin UZS hamyonida - eng katta qiymatni ko'rsatish
          print('   → UZS wallet, wallets not found: using larger amount');
          final largerAmount = t.amountChiqim! > t.amountKirim! 
              ? t.amountChiqim! 
              : t.amountKirim!;
          return '${_formatNumberWithDecimal(largerAmount)} som';
        }
      }
    }

    // IKKINCHI: Comment'dan parse qilish (eski usul - backup)
    String titleText = t.title;
    String descText = (t.description ?? '') + ' ' + (t.notes ?? '');
    String allText = titleText + ' ' + descText;
    print('DEBUG CONVERSION: Parsing text: "$allText"');

    // Enhanced parsing - multiple formats:
    // "100 → 1100000", "Conversion: 100 → 1100000", "(100 → 1100000)", "(10000.0 → 0.83)"
    List<RegExp> conversionPatterns = [
      RegExp(
        r'Conversion:\s*(\d+(?:\.\d+)?(?:\s*\d+)*)\s*[→>-]+\s*(\d+(?:\.\d+)?(?:\s*\d+)*)',
        caseSensitive: false,
      ),
      RegExp(
        r'[\(\[](\d+(?:\.\d+)?(?:\s*\d+)*)\s*[→>-]+\s*(\d+(?:\.\d+)?(?:\s*\d+)*)[\)\]]',
        caseSensitive: false,
      ),
      RegExp(
        r'(\d+(?:\.\d+)?(?:\s*\d+)*)\s*[→>-]+\s*(\d+(?:\.\d+)?(?:\s*\d+)*)',
        caseSensitive: false,
      ),
    ];

    for (var pattern in conversionPatterns) {
      var match = pattern.firstMatch(allText);
      if (match != null) {
        String fromAmountStr =
            match.group(1)?.replaceAll(RegExp(r'\s+'), '') ?? '';
        String toAmountStr =
            match.group(2)?.replaceAll(RegExp(r'\s+'), '') ?? '';

        print('🔍 REGEX MATCH FOUND:');
        print('   Raw group(1): "${match.group(1)}"');
        print('   Raw group(2): "${match.group(2)}"');
        print('   Cleaned fromAmountStr: "$fromAmountStr"');
        print('   Cleaned toAmountStr: "$toAmountStr"');

        if (fromAmountStr.isNotEmpty && toAmountStr.isNotEmpty) {
          double fromAmount = double.tryParse(fromAmountStr) ?? 0;
          double toAmount = double.tryParse(toAmountStr) ?? 0;

          print('   Parsed fromAmount: $fromAmount');
          print('   Parsed toAmount: $toAmount');
          print(
            '   Current wallet: $currentWalletCurrency, isChiqimUSD: $isChiqimUSD, isKirimUSD: $isKirimUSD',
          );

          if (fromAmount > 0 && toAmount > 0) {
            // Logic: current hamyon asosida amount ni aniqlash
            if (currentWalletCurrency == 'USD') {
              // USD hamyonida ko'rayotgan bo'lsak
              if (isChiqimUSD) {
                // USD chiqim (USD → UZS), USD amount ko'rsatish
                print('   ✅ BRANCH: USD wallet, USD chiqim -> show fromAmount');
                return '\$${_formatUSDAmount(fromAmount)}';
              } else if (isKirimUSD) {
                // USD kirim (UZS → USD), USD amount ko'rsatish
                print('   ✅ BRANCH: USD wallet, USD kirim -> show toAmount');
                return '\$${_formatUSDAmount(toAmount)}';
              } else {
                // Noma'lum holat, kichikroq raqamni USD deb hisoblaymiz
                print('   ✅ BRANCH: USD wallet, unknown -> show smaller');
                double usdAmount = fromAmount < toAmount
                    ? fromAmount
                    : toAmount;
                return '\$${_formatUSDAmount(usdAmount)}';
              }
            } else {
              // UZS hamyonida ko'rayotgan bo'lsak
              if (isChiqimUSD) {
                // USD chiqim (USD → UZS), UZS amount ko'rsatish (kasr bilan)
                print(
                  '   ✅ BRANCH: UZS wallet, USD chiqim -> show toAmount: $toAmount',
                );
                return '${_formatNumberWithDecimal(toAmount)} som';
              } else if (isKirimUSD) {
                // USD kirim (UZS → USD), UZS amount ko'rsatish (kasr bilan)
                print(
                  '   ✅ BRANCH: UZS wallet, USD kirim -> show fromAmount: $fromAmount',
                );
                return '${_formatNumberWithDecimal(fromAmount)} som';
              } else {
                // Noma'lum holat, kattaroq raqamni UZS deb hisoblaymiz
                print('   ✅ BRANCH: UZS wallet, unknown -> show larger');
                double uzsAmount = fromAmount > toAmount
                    ? fromAmount
                    : toAmount;
                return '${_formatNumberWithDecimal(uzsAmount)} som';
              }
            }
          }
        }
        break; // First successful match
      }
    }

    // API'dan amount tekshirish (backup method)
    if (t.amount > 0) {
      print('DEBUG CONVERSION: Using t.amount as fallback: ${t.amount}');
      return '${_formatNumber(t.amount.toInt())} ${_getCurrencySymbol()}';
    }

    if (t.amountDebit != null && t.amountDebit! > 0) {
      print(
        'DEBUG CONVERSION: Using t.amountDebit as fallback: ${t.amountDebit}',
      );
      return '${_formatNumber(t.amountDebit!.toInt())} ${_getCurrencySymbol()}';
    }

    // Final fallback: smart estimation
    print('DEBUG CONVERSION: Using smart estimation as final fallback');

    double estimatedAmount;
    if (currentWalletCurrency == 'USD') {
      estimatedAmount = 100; // $100 default
    } else {
      estimatedAmount = 1100000; // 1.1M UZS default
    }

    return '${_formatNumber(estimatedAmount.toInt())} ${_getCurrencySymbol()}';
  }

  // Konvertatsiya summalarini avtomatik hisoblash
  void _calculateConversionAmount(
    String value,
    TextEditingController chiqimCtrl,
    TextEditingController kirimCtrl,
    String? chiqimWalletId,
    String? kirimWalletId,
    bool isChiqimChanged,
    void Function(void Function()) setState,
  ) {
    // Bo'sh bo'lsa hisoblash
    if (value.trim().isEmpty) return;

    // Hamyonlar tanlanmagan bo'lsa return
    if (chiqimWalletId == null || kirimWalletId == null) return;

    // Hamyonlarni topish
    final chiqimWallet = _walletsList.firstWhere(
      (w) => w['walletId'] == chiqimWalletId,
      orElse: () => <String, dynamic>{},
    );
    final kirimWallet = _walletsList.firstWhere(
      (w) => w['walletId'] == kirimWalletId,
      orElse: () => <String, dynamic>{},
    );

    if (chiqimWallet.isEmpty || kirimWallet.isEmpty) return;

    final chiqimCurrency =
        chiqimWallet['currency']?.toString().toUpperCase() ?? 'UZS';
    final kirimCurrency =
        kirimWallet['currency']?.toString().toUpperCase() ?? 'UZS';

    // Bir xil valyuta bo'lsa hisoblash kerak emas
    if (chiqimCurrency == kirimCurrency) return;

    // Faqat USD ↔ UZS konvertatsiyasi uchun
    if (!((chiqimCurrency == 'USD' && kirimCurrency == 'UZS') ||
        (chiqimCurrency == 'UZS' && kirimCurrency == 'USD')))
      return;

    // Kiritilgan summani parse qilish - probel va vergulni olib tashlash
    final amount = double.tryParse(
      value.replaceAll(' ', '').replaceAll(',', ''),
    );
    if (amount == null || amount <= 0) return;

    // Debug: Kurs va hisoblash ma'lumotlari
    print('💱 ===== AUTO-CALCULATION DEBUG =====');
    print('   Exchange rate: $_exchangeRate');
    print('   Input value (string): "$value"');
    print('   Parsed amount: $amount');
    print('   From currency: $chiqimCurrency → To currency: $kirimCurrency');
    print('   Is chiqim changed: $isChiqimChanged');

    double convertedAmount;

    if (isChiqimChanged) {
      // Chiqim o'zgardi - kirimni hisoblash
      if (chiqimCurrency == 'USD' && kirimCurrency == 'UZS') {
        // USD → UZS
        convertedAmount = amount * _exchangeRate;
        print(
          '   ✅ Calculation: $amount USD × $_exchangeRate = $convertedAmount UZS',
        );
      } else {
        // UZS → USD
        convertedAmount = amount / _exchangeRate;
        print(
          '   ✅ Calculation: $amount UZS ÷ $_exchangeRate = $convertedAmount USD',
        );
      }

      // Kirim field'ini yangilash
      final newKirimText = kirimCurrency == 'USD'
          ? convertedAmount.toStringAsFixed(2)
          : NumberFormatterHelper.formatNumber(convertedAmount);

      print('   📝 Setting kirim field to: "$newKirimText"');

      setState(() {
        kirimCtrl.text = newKirimText;
      });
    } else {
      // Kirim o'zgardi - chiqimni hisoblash
      if (kirimCurrency == 'USD' && chiqimCurrency == 'UZS') {
        // USD kirim, UZS chiqim
        convertedAmount = amount * _exchangeRate;
        print(
          '   ✅ Calculation: $amount USD × $_exchangeRate = $convertedAmount UZS',
        );
      } else {
        // UZS kirim, USD chiqim
        convertedAmount = amount / _exchangeRate;
        print(
          '   ✅ Calculation: $amount UZS ÷ $_exchangeRate = $convertedAmount USD',
        );
      }

      // Chiqim field'ini yangilash
      final newChiqimText = chiqimCurrency == 'USD'
          ? convertedAmount.toStringAsFixed(2)
          : NumberFormatterHelper.formatNumber(convertedAmount);

      print('   📝 Setting chiqim field to: "$newChiqimText"');

      setState(() {
        chiqimCtrl.text = newChiqimText;
      });
    }

    print('   💚 Auto-calculation completed');
    print('   ====================================');
  }
}
