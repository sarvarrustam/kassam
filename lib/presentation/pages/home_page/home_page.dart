import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kassam/core/services/connectivity_service.dart';
import 'package:kassam/data/models/wallet_balance_model.dart';
import 'package:kassam/presentation/blocs/user/user_bloc.dart';
import 'package:kassam/presentation/pages/no_internet_page.dart';
import '../../theme/app_colors.dart';

import 'bloc/home_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _showBalance = true;
  bool _showAddMenu = false;
  final ConnectivityService _connectivityService = ConnectivityService();

  // Cache uchun
  List<WalletBalance>? _cachedWallets;
  double? _cachedSomTotal;
  double? _cachedDollarTotal;
  String? _cachedUserName;
  double _exchangeRate = 12000.0; // Default kurs

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    // Frame render bo'lgandan keyin ishga tushirish
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initial data yuklash
      context.read<HomeBloc>().add(HomeGetWalletsEvent());
      context.read<HomeBloc>().add(HomeGetTotalBalancesEvent());
      context.read<HomeBloc>().add(HomeGetExchangeRateEvent());
      context.read<UserBloc>().add(UserGetDataEvent());
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<HomeBloc, HomeState>(
          listener: (context, state) {
            if (state is HomeError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            } else if (state is HomeGetWalletsSuccess) {
              _cachedWallets = state.wallets;
            } else if (state is HomeGetTotalBalancesSuccess) {
              _cachedSomTotal = state.somTotal;
              _cachedDollarTotal = state.dollarTotal;
            } else if (state is HomeWalletCreatedSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Hamyon muvaffaqiyatli yaratildi'),
                  backgroundColor: AppColors.primaryGreen,
                ),
              );
            } else if (state is HomeGetExchangeRateSuccess) {
              setState(() {
                _exchangeRate = state.rate;
              });
            }
          },
        ),
        BlocListener<UserBloc, UserState>(
          listener: (context, state) {
            if (state is UserLoaded) {
              setState(() {
                _cachedUserName = state.user.name.isEmpty
                    ? 'Foydalanuvchi'
                    : state.user.name;
              });
            } else if (state is UserError) {
              print('❌ User error: ${state.message}');
            }
          },
        ),
      ],
      child: Stack(
        children: [
          BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              // Cache dan ma'lumotlarni olish
              final wallets = _cachedWallets ?? [];
              final totalUZS = _cachedSomTotal ?? 0;
              final totalUSD = _cachedDollarTotal ?? 0;

              return RefreshIndicator(
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

                  // Ma'lumotlarni yangilash
                  context.read<HomeBloc>().add(HomeGetWalletsEvent());
                  context.read<HomeBloc>().add(HomeGetTotalBalancesEvent());
                  context.read<HomeBloc>().add(HomeGetExchangeRateEvent());
                  context.read<UserBloc>().add(UserGetDataEvent());

                  // API chaqiruvlari tugashini kutish (2 sekund)
                  await Future.delayed(const Duration(seconds: 2));
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primaryGreen,
                              AppColors.primaryGreenLight,
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 40),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _cachedUserName != null
                                      ? ' $_cachedUserName!'
                                      : 'Xush kelibsiz!',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                // Kurs ko'rsatish
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Kurs \$',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(1),
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_formatNumber(_exchangeRate.toInt())} so\'m',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            GestureDetector(
                              onTap: () {
                                final next = (_currentPage + 1) % 3;
                                _pageController.animateToPage(
                                  next,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  //color:Colors.greenAccent,
                                );
                              },
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 100,
                                    child: PageView.builder(
                                      controller: _pageController,
                                      itemCount: 3,
                                      onPageChanged: (index) {
                                        setState(() {
                                          _currentPage = index;
                                        });
                                      },
                                      itemBuilder: (context, index) {
                                        if (index == 0) {
                                          final uzsToUsdConversion =
                                              totalUZS / _exchangeRate;
                                          return _buildBalanceCard(
                                            'Mening Pulim',
                                            '${_formatNumber(totalUZS.toInt())} UZS',
                                            subtitle:
                                                '≈ ${uzsToUsdConversion.toStringAsFixed(2)} USD',
                                          );
                                        } else if (index == 1) {
                                          final usdToUzsConversion =
                                              (totalUSD * _exchangeRate)
                                                  .toInt();
                                          return _buildBalanceCard(
                                            'Mening Dollarim',
                                            '${_formatNumber(totalUSD.toInt())} USD',
                                            subtitle:
                                                '≈ ${_formatNumber(usdToUzsConversion)} UZS',
                                          );
                                        }

                                        // 3-chi tab: Jami
                                        // UZS: 1-oynadagi UZS + (2-oynadagi USD * kurs)
                                        final totalUzsWithUsdConverted = totalUZS + (totalUSD * _exchangeRate);
                                        // USD: 2-oynadagi USD + (1-oynadagi UZS / kurs)
                                        final totalUsdWithUzsConverted = totalUSD + (totalUZS / _exchangeRate);
                                        
                                        return _buildTotalBalanceCard(
                                          totalUzsWithUsdConverted.toInt(),
                                          totalUsdWithUzsConverted,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildPageIndicator(0),
                                      _buildPageIndicator(1),
                                      _buildPageIndicator(2),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Hamyonlar Grid
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Mening Hamyonlarim',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                // Plus tugmasi
                                Material(
                                  elevation: 2,
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    onTap: () {
                                      print('➕ Plus bosildi');
                                      setState(() {
                                        _showAddMenu = !_showAddMenu;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      height: 40,
                                      width: 40,
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                          255,
                                          53,
                                          210,
                                          181,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        _showAddMenu ? Icons.close : Icons.add,
                                        color: const Color.fromARGB(
                                          255,
                                          248,
                                          250,
                                          249,
                                        ),
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Dropdown menu - inline
                            if (_showAddMenu)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Material(
                                  elevation: 8,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            print(
                                              '🔧 Hamyon qo\'shish bosildi',
                                            );
                                            setState(() {
                                              _showAddMenu = false;
                                            });
                                            _showAddWalletSheet();
                                          },
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            topRight: Radius.circular(12),
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.account_balance_wallet,
                                                  color: AppColors.primaryGreen,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 12),
                                                const Text(
                                                  'Hamyon qo\'shish',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Divider(
                                          height: 1,
                                          color: Colors.grey[300],
                                        ),
                                        InkWell(
                                          onTap: () {
                                            print('💵 Kurs kiritish bosildi');
                                            setState(() {
                                              _showAddMenu = false;
                                            });
                                            _showUpdateExchangeRateSheet();
                                          },
                                          borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(12),
                                            bottomRight: Radius.circular(12),
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.attach_money,
                                                  color: AppColors.primaryGreen,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 12),
                                                const Text(
                                                  'Kurs kiritish',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
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
                              ),
                            if (state is HomeWalletsLoading)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (wallets.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: Text('Hamyonlar topilmadi'),
                                ),
                              )
                            else
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  // Kartalarni 2 tadan qatorlarga bo'lish
                                  List<Widget> rows = [];
                                  for (int i = 0; i < wallets.length; i += 2) {
                                    List<Widget> rowChildren = [];

                                    // 1-chi karta
                                    rowChildren.add(
                                      Expanded(
                                        child: _buildWalletCard(wallets[i], i),
                                      ),
                                    );

                                    // 2-chi karta (agar qatorda bo'lsa)
                                    if (i + 1 < wallets.length) {
                                      rowChildren.add(
                                        const SizedBox(width: 12),
                                      );
                                      rowChildren.add(
                                        Expanded(
                                          child: _buildWalletCard(
                                            wallets[i + 1],
                                            i + 1,
                                          ),
                                        ),
                                      );
                                    } else {
                                      // Bo'sh joy
                                      rowChildren.add(
                                        const SizedBox(width: 12),
                                      );
                                      rowChildren.add(
                                        const Expanded(child: SizedBox()),
                                      );
                                    }

                                    rows.add(
                                      IntrinsicHeight(
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: rowChildren,
                                        ),
                                      ),
                                    );

                                    // Qatorlar orasida masofa
                                    if (i + 2 < wallets.length) {
                                      rows.add(const SizedBox(height: 12));
                                    }
                                  }

                                  return Column(children: rows);
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPage == index ? Colors.white : Colors.white54,
      ),
    );
  }

  Widget _buildBalanceCard(String title, String amount, {String? subtitle}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),

        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 4),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showBalance = !_showBalance;
                    });
                  },
                  child: Icon(
                    _showBalance ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white.withOpacity(0.7),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  _showBalance ? amount : '••••••',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(width: 8),
                Text(
                  _showBalance ? subtitle : '••••••',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    final str = number.toString();
    final reversed = str.split('').reversed.toList();
    final parts = <String>[];

    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        parts.add(' ');
      }
      parts.add(reversed[i]);
    }

    return parts.reversed.join('');
  }

  Widget _buildTotalBalanceCard(int totalInUZS, double totalInUSD) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Jami',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showBalance = !_showBalance;
                  });
                },
                child: Icon(
                  _showBalance ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white.withOpacity(0.7),
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _showBalance
                          ? '${_formatNumber(totalInUZS)} UZS'
                          : '••••••',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _showBalance
                          ? '${totalInUSD.toStringAsFixed(2)} USD'
                          : '••••••',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //bu qism meni ano tepadigi plusni bosgand aochladigan showdilaogm
  Widget _buildWalletCard(WalletBalance wallet, int index) {
    final formattedAmount = _formatNumber(wallet.value.toInt());
    final displayText = _showBalance
        ? '$formattedAmount ${wallet.currency}'
        : '•••••• ${wallet.currency}';

    // Summa uzunligiga qarab font size
    double fontSize = 15;
    if (formattedAmount.length > 12) {
      fontSize = 12;
    } else if (formattedAmount.length > 9) {
      fontSize = 13;
    } else if (formattedAmount.length > 6) {
      fontSize = 14;
    }

    return GestureDetector(
      onTap: () async {
        await context.push(
          '/stats?walletId=${wallet.id}&walletName=${Uri.encodeComponent(wallet.name)}&walletCurrency=${wallet.type}',
        );
        // Stats page'dan qaytganda hamyonlarni yangilash
        if (mounted) {
          context.read<HomeBloc>().add(HomeGetWalletsEvent());
          context.read<HomeBloc>().add(HomeGetTotalBalancesEvent());
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryGreen, AppColors.primaryGreenLight],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withOpacity(0.3),
              offset: const Offset(0, 3),
              blurRadius: 8,
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.wallet_rounded, size: 32, color: Colors.white),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              wallet.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              displayText,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddWalletSheet() {
    final TextEditingController nameController = TextEditingController();
    int selectedTabIndex = 0; // 0 = UZS, 1 = USD

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
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
                  const SizedBox(height: 24),
                  const Text(
                    'Yangi hamyon qo\'shish',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  // Hamyon nomi input - yuqorida
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Hamyon nomi',
                      hintText: 'Masalan: Asosiy hamyon',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // TabBar - pastda
                  DefaultTabController(
                    length: 2,
                    initialIndex: selectedTabIndex,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TabBar(
                          tabs: const [
                            Tab(text: 'UZS (So\'m)'),
                            Tab(text: 'USD (Dollar)'),
                          ],
                          labelColor: AppColors.primaryGreen,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: AppColors.primaryGreen,
                          onTap: (index) {
                            selectedTabIndex = index;
                            setModalState(() {});
                          },
                        ),
                        const SizedBox(height: 24),
                        // Bitta button - TabBar'dan tashqarida
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              final name = nameController.text.trim();
                              if (name.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Hamyon nomini kiriting'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              // selectedTabIndex'ga qarab currency'ni aniqlash
                              final currency = selectedTabIndex == 0
                                  ? 'uzs'
                                  : 'usd';

                              // BLoC orqali hamyon yaratish
                              context.read<HomeBloc>().add(
                                HomeCreateWalletEvent(
                                  name: name,
                                  currency: currency,
                                ),
                              );

                              Navigator.pop(ctx);
                              nameController.clear();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              selectedTabIndex == 0
                                  ? 'So\'m hamyon qo\'shish'
                                  : 'Dollar hamyon qo\'shish',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showUpdateExchangeRateSheet() {
    final TextEditingController kursController = TextEditingController(
      text: _formatNumber(_exchangeRate.toInt()),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
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
              const SizedBox(height: 24),
              const Text(
                'Kurs yangilash',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              // Kurs input
              TextField(
                controller: kursController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Kurs (1\$ = ? so\'m)',
                  hintText: 'Masalan: 12 500',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  // Space'larni olib tashlash va formatlab qayta qo'yish
                  final clean = value.replaceAll(' ', '');
                  if (clean.isEmpty) return;

                  final number = int.tryParse(clean);
                  if (number != null) {
                    final formatted = _formatNumber(number);
                    if (kursController.text != formatted) {
                      kursController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(
                          offset: formatted.length,
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 24),
              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final kurs = kursController.text.trim().replaceAll(' ', '');
                    if (kurs.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kursni kiriting'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final kursValue = double.tryParse(kurs);
                    if (kursValue == null || kursValue <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('To\'g\'ri kurs kiriting'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Header'dagi kurs'ni yangilash
                    setState(() {
                      _exchangeRate = kursValue;
                    });

                    // BLoC orqali API'ga kurs jo'natish
                    context.read<HomeBloc>().add(
                      HomeUpdateExchangeRateEvent(kurs: kursValue),
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Kurs yangilandi'),
                        backgroundColor: AppColors.primaryGreen,
                      ),
                    );

                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Kurs saqlash',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
