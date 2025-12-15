import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../presentation/theme/app_colors.dart';
import '../../../arch/bloc/theme_bloc.dart';
import '../../../data/services/app_preferences_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Abdullayev Anvar',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '+998 (99) 123 45 67',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Settings Sections
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Appearance Section
                    Text(
                      'Ko\'rinish',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSettingItem(
                      context,
                      icon: Icons.brightness_4,
                      title: 'Tungi Rejim',
                      subtitle: 'Qo\'ng\'iroq sistemasi ',
                      trailing: Switch(
                        value: state.isDarkMode,
                        onChanged: (value) {
                          context.read<ThemeBloc>().add(ToggleThemeEvent());
                        },
                        activeColor: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSettingItem(
                      context,
                      icon: Icons.language,
                      title: 'Til',
                      subtitle: 'O\'zbek (UZ)',
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {},
                    ),
                    const SizedBox(height: 24),
                    // Account Section
                    Text(
                      'Akkaunt',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSettingItem(
                      context,
                      icon: Icons.person_outline,
                      title: 'Profil',
                      subtitle: 'Shaxsiy ma\'lumotlarni tahrir qiling',
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {},
                    ),
                    const SizedBox(height: 16),
                    _buildSettingItem(
                      context,
                      icon: Icons.security,
                      title: 'Xavfsizlik',
                      subtitle: 'Parol va ruxsatlar',
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {},
                    ),
                    const SizedBox(height: 16),
                    _buildSettingItem(
                      context,
                      icon: Icons.notifications_outlined,
                      title: 'Bildirishnomalar',
                      subtitle: 'Bildirishnomalarni sozlash',
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {},
                    ),
                    const SizedBox(height: 24),
                    // General Section
                    Text(
                      'Umumiy',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSettingItem(
                      context,
                      icon: Icons.info_outline,
                      title: 'Dastur Haqida',
                      subtitle: 'Versiya: 1.0.0',
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {},
                    ),
                    const SizedBox(height: 16),
                    _buildSettingItem(
                      context,
                      icon: Icons.help_outline,
                      title: 'Yordam',
                      subtitle: 'Ko\'makka muhtoj bo\'lsangiz',
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {},
                    ),
                    const SizedBox(height: 24),
                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Chiqish'),
                              content: const Text(
                                'Akkauntdan chiqib ketmoqchisiz?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Bekor qilish'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    // Onboarding ni reset qilish
                                    final prefs = AppPreferencesService();
                                    await prefs.resetOnboarding();
                                    // Entry sahifasiga o'tish
                                    if (context.mounted) {
                                      context.go('/entry');
                                    }
                                  },
                                  child: const Text(
                                    'Chiqish',
                                    style: TextStyle(color: AppColors.errorRed),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Akkauntdan Chiqish'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.errorRed,
                          side: const BorderSide(color: AppColors.errorRed),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderGrey),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(icon, color: AppColors.primaryGreen, size: 24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
