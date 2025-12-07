import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kassam/data/services/mock_data_service.dart';
import '../../theme/app_colors.dart';
import 'bloc/home_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final double _exchangeRate = 11500.0;
  late final PageController _pageController;
  int _currentPage = 0;
  final _dataService = MockDataService();
  bool _showBalance = true; // Balance visibility toggle

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    // BLoC orqali user ma'lumotlarini yuklash
    context.read<HomeBloc>().add(HomeLoadUserData());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
          // Username ni state dan olish
          String displayName = 'Foydalanuvchi'; // Default
          double totalUZS = 0;
          double totalUSD = 0;
          List<Map<String, dynamic>> wallets = [];
          
          if (state is HomeLoaded) {
            displayName = state.userName;
            totalUZS = state.totalUZS ?? 0;
            totalUSD = state.totalUSD ?? 0;
            wallets = state.wallets ?? [];
          } else if (state is HomeLoading) {
            displayName = 'Yuklanmoqda...';
          }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryGreen, AppColors.primaryGreenLight],
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
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                const SizedBox(height: 32),
                // Balance Card (Swipeable UZS <-> USD)
                GestureDetector(
                  onTap: () {
                    final next = 1 - _currentPage;
                    _pageController.animateToPage(
                      next,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
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
                              // API dan kelgan UZS balansi
                              final uzsToUsdConversion =
                                  (totalUZS / _exchangeRate).toInt();
                              return _buildBalanceCard(
                                'Mening Pulim',
                                '${_formatNumber(totalUZS.toInt())} UZS',
                                subtitle:
                                    '≈ ${_formatNumber(uzsToUsdConversion)} USD',
                              );
                            } else if (index == 1) {
                              // API dan kelgan USD balansi
                              final usdToUzsConversion =
                                  (totalUSD * _exchangeRate).toInt();
                              return _buildBalanceCard(
                                'Mening Dollarim',
                                '${_formatNumber(totalUSD.toInt())} USD',
                                subtitle:
                                    '≈ ${_formatNumber(usdToUzsConversion)} UZS',
                              );
                            }

                            // 3-chi tab: Jami (umumiy) - API dan
                            return _buildTotalBalanceCard(
                              totalUZS.toInt(),
                              totalUSD.toInt(),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentPage == 0
                                  ? Colors.white
                                  : Colors.white54,
                            ),
                          ),
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentPage == 1
                                  ? Colors.white
                                  : Colors.white54,
                            ),
                          ),
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentPage == 2
                                  ? Colors.white
                                  : Colors.white54,
                            ),
                          ),
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
                Text(
                  'Mening Hamyonlarim',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: wallets.length,
                  itemBuilder: (ctx, i) {
                    final w = wallets[i];
                    // API dan kelgan ma'lumotlarni olish
                    final walletName = w['name'] ?? 'Hamyon';
                    final walletBalance = (w['value'] ?? 0).toDouble(); // 'balance' emas, 'value'
                    final walletType = (w['type'] ?? 'som').toString().toLowerCase();
                    
                    // Type ni valyuta kodiga o'tkazish
                    String walletCurrency;
                    if (walletType == 'dollar') {
                      walletCurrency = 'USD';
                    } else if (walletType == 'som') {
                      walletCurrency = 'UZS';
                    } else {
                      walletCurrency = 'UZS'; // Default
                    }
                    
                    final walletId = w['id'] ?? '';
                    final isDefault = (w['isDefault'] ?? false) || i == 0; // Birinchi hamyon default
                    
                    print('👛 Wallet #$i: name=$walletName, value=$walletBalance, type=$walletType -> currency=$walletCurrency');
                    
                    return GestureDetector(
                      onTap: () => context.push('/stats?walletId=$walletId'),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primaryGreen,
                              AppColors.primaryGreenLight,
                            ],
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(
                                  Icons.wallet_rounded,
                                  size: 32,
                                  color: Colors.white,
                                ),
                                if (isDefault)
                                  const Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  walletName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _showBalance
                                      ? '${_formatNumber(walletBalance.toInt())} $walletCurrency'
                                      : '•••••• $walletCurrency',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                // Konvertsiya ko'rsatilmaydi - faqat o'z valyutasi
                                // if (w.currency == 'UZS')
                                //   Text(
                                //     '${_formatNumber((w.balance / _exchangeRate).toInt())} USD',
                                //     style: const TextStyle(
                                //       color: Colors.white,
                                //       fontSize: 10,
                                //     ),
                                //     maxLines: 1,
                                //     overflow: TextOverflow.ellipsis,
                                //   ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
            ),
          );
        },
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
            children: [
              Text(
                title,
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
          const SizedBox(height: 10),
          Text(
            _showBalance ? amount : '••••••',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            // const SizedBox(height: 4),
            Text(
              _showBalance ? subtitle : '••••••',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    // Uzbek number format: spaces as thousands separator
    // Example: 1 234 567 instead of 1,234,567
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

  Widget _buildTotalBalanceCard(int totalInUZS, int totalInUSD) {
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
          // Ikki column: UZS (chap) va USD (o'ng)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Chap: UZS jami
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
              // O'ng: USD jami
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _showBalance
                          ? '${_formatNumber(totalInUSD)} USD'
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
}
