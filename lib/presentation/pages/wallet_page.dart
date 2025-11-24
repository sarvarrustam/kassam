import 'package:flutter/material.dart';
import 'package:kassam/presentation/theme/app_colors.dart';
import 'package:kassam/data/models/wallet_model.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final List<Wallet> _wallets = [
    Wallet(
      id: '1',
      name: 'Asosiy Hisob',
      type: WalletType.checking,
      balance: 3500000,
      currency: 'UZS',
      color: '388E3C',
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      isDefault: true,
    ),
    Wallet(
      id: '2',
      name: 'Jamg\'al',
      type: WalletType.savings,
      balance: 8500000,
      currency: 'UZS',
      color: '2196F3',
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
    ),
    Wallet(
      id: '3',
      name: 'Visa Card',
      type: WalletType.card,
      balance: 1200000,
      currency: 'UZS',
      color: 'FF9800',
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
  ];

  double get _totalBalance => _wallets.fold(0, (sum, w) => sum + w.balance);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hamyonlar'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Yangi hamyon qo\'shish')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Jami Balance
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryGreen,
                    AppColors.primaryGreen.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jami Balans',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_totalBalance.toStringAsFixed(0)} UZS',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _QuickActionButton(
                        icon: Icons.arrow_downward,
                        label: 'Kirim',
                        onTap: () {},
                      ),
                      _QuickActionButton(
                        icon: Icons.arrow_upward,
                        label: 'Chiqim',
                        onTap: () {},
                      ),
                      _QuickActionButton(
                        icon: Icons.swap_horiz,
                        label: 'O\'tkazma',
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Hamyonlar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mening Hamyonlarim',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Hammasini Ko\'r'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ListView.builder(
            //   shrinkWrap: true,
            //   physics: const NeverScrollableScrollPhysics(),
            //   itemCount: _wallets.length,
            //   itemBuilder: (context, index) {
            //     final wallet = _wallets[index];
            //     return WalletCard(wallet: wallet);
            //   },
            // ),
            const SizedBox(height: 24),

            // Tez Amallar
            // const Text(
            //   'Tez Amallar',
            //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            // ),
            // const SizedBox(height: 12),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceAround,
            //   children: [
            //     _ActionCard(
            //       icon: Icons.card_giftcard,
            //       label: 'To\'lovni\nUshbu',
            //       color: AppColors.primaryGreen,
            //       onTap: () {},
            //     ),
            //     _ActionCard(
            //       icon: Icons.compare_arrows,
            //       label: 'Hamyonlar\nO\'rtasida',
            //       color: const Color(0xFF2196F3),
            //       onTap: () {},
            //     ),
            //     _ActionCard(
            //       icon: Icons.history,
            //       label: 'O\'tkazma\nTarixi',
            //       color: const Color(0xFFFF9800),
            //       onTap: () {},
            //     ),
            //     _ActionCard(
            //       icon: Icons.settings,
            //       label: 'Hamyon\nSozlamalari',
            //       color: const Color(0xFF9C27B0),
            //       onTap: () {},
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }
}

class WalletCard extends StatelessWidget {
  final Wallet wallet;

  const WalletCard({required this.wallet, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Color(
              int.parse('FF${wallet.color}', radix: 16),
            ).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              wallet.getTypeIcon(),
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              wallet.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (wallet.isDefault) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Default',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(wallet.getTypeName()),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              wallet.balance.toStringAsFixed(0),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              wallet.currency,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        onTap: () {
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
                  Text(
                    wallet.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Tahrirlash'),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text(
                      'O\'chirish',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
