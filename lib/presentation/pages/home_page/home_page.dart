import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kassam/data/services/mock_data_service.dart';
import '../../theme/app_colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final double _balanceSom = 125000.0;
  final double _exchangeRate = 11500.0;
  bool _showSomPrimary = true;
  late final PageController _pageController;
  int _currentPage = 0;
  final _dataService = MockDataService();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                Column(
                  // crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    SizedBox(height: 10),
                  ],
                ),
                Text(
                  'Abdulaziz',
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
                          itemCount: 2,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPage = index;
                              _showSomPrimary = index == 0;
                            });
                          },
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return _buildBalanceCard(
                                'Mening Pulim',
                                '${_balanceSom.toStringAsFixed(0)} UZS',
                              );
                            }

                            return _buildBalanceCard(
                              'Mening Dollarim',
                              '${(_balanceSom / _exchangeRate).toStringAsFixed(2)} USD',
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
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _dataService.getWallets().length,
                  itemBuilder: (ctx, i) {
                    final w = _dataService.getWallets()[i];
                    return GestureDetector(
                      onTap: () => context.push('/stats'),

                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(int.parse('AA${w.color}', radix: 16)),
                              Color(
                                int.parse('AA${w.color}', radix: 16),
                              ).withOpacity(0.1),
                            ],
                            //begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent.withOpacity(1),
                              // blurRadius: 10,
                              offset: const Offset(0, 3),
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
                                Text(
                                  w.getTypeIcon(),
                                  style: const TextStyle(fontSize: 32),
                                ),
                                if (w.isDefault)
                                  const Icon(
                                    Icons.wallet_rounded,
                                    // color: Colors.amber,
                                    size: 16,
                                  ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                Text(
                                  w.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${w.balance.toStringAsFixed(0)} ${w.currency}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
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

          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 24),
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Text(
          //         ' Amallar',
          //         style: Theme.of(
          //           context,
          //         ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          //       ),
          //       const SizedBox(height: 16),
          //       Row(
          //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //         children: [
          //           _buildActionButton(
          //             context,
          //             icon: Icons.arrow_upward_rounded,
          //             label: 'Xarajat',
          //             color: AppColors.errorRed,
          //           ),
          //           _buildActionButton(
          //             context,
          //             icon: Icons.arrow_downward_rounded,
          //             label: 'Daromad',
          //             color: AppColors.successGreen,
          //           ),

          //           _buildActionButton(
          //             context,
          //             icon: Icons.add,
          //             label: 'Boshqa',
          //             color: AppColors.warningOrange,
          //           ),
          //         ],
          //       ),
          //     ],
          //   ),
          // ),
          // const SizedBox(height: 32),
          // // Recent Transactions
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 24),
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Row(
          //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //         children: [
          //           Text(
          //             'So\'nggi Tranzaksiyalar',
          //             style: Theme.of(context).textTheme.titleLarge?.copyWith(
          //               fontWeight: FontWeight.w700,
          //             ),
          //           ),
          //           GestureDetector(
          //             onTap: () => context.push('/transactions-list'),
          //             child: Text(
          //               'Barchasi',
          //               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          //                 color: AppColors.primaryGreen,
          //                 fontWeight: FontWeight.w600,
          //               ),
          //             ),
          //           ),
          //         ],
          //       ),
          //       const SizedBox(height: 16),
          //       // Empty State
          //       Container(
          //         decoration: BoxDecoration(
          //           border: Border.all(color: AppColors.borderGrey),
          //           borderRadius: BorderRadius.circular(12),
          //         ),
          //         padding: const EdgeInsets.all(32),
          //         child: Center(
          //           child: Column(
          //             children: [
          //               Icon(
          //                 Icons.history,
          //                 size: 48,
          //                 color: AppColors.textSecondary.withOpacity(0.5),
          //               ),
          //               const SizedBox(height: 16),
          //               Text(
          //                 'Hali Tranzaksiya Yo\'q',
          //                 style: Theme.of(context).textTheme.bodyLarge
          //                     ?.copyWith(color: AppColors.textSecondary),
          //               ),
          //             ],
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          // const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(String title, String amount) {
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
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          Text(
            amount,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.2),
            ),
            child: Center(child: Icon(icon, color: color, size: 28)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
