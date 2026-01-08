import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kassam/presentation/blocs/user/user_bloc.dart';
import '../../theme/app_colors.dart';
import '../../../arch/bloc/theme_bloc.dart';

import '../../../data/services/app_preferences_service.dart';
import '../../../data/services/biometric_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _biometricService = BiometricService();
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  String _biometricType = 'Biometrik';

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final isSupported = await _biometricService.isDeviceSupported();
    final canCheck = await _biometricService.canCheckBiometrics();
    final types = await _biometricService.getAvailableBiometrics();
    final prefs = AppPreferencesService();
    final isEnabled = await prefs.isBiometricEnabled();

    if (mounted) {
      setState(() {
        _isBiometricAvailable = isSupported && canCheck && types.isNotEmpty;
        _isBiometricEnabled = isEnabled;
        _biometricType = _biometricService.getBiometricTypeName(types);
      });
    }
  }

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
                        Expanded(
                          child: BlocBuilder<UserBloc, UserState>(
                            builder: (context, userState) {
                              String userName = 'Foydalanuvchi';
                              String userPhone = '';
                              
                              if (userState is UserLoaded) {
                                userName = userState.user.name ?? 'Foydalanuvchi';
                               // userPhone = userState.user.phone ?? '';
                              }
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName,
                                    style: Theme.of(context).textTheme.headlineSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  if (userPhone.isNotEmpty)
                                    Text(
                                      userPhone,
                                      style: Theme.of(context).textTheme.bodyMedium
                                          ?.copyWith(color: Colors.white70),
                                    ),
                                ],
                              );
                            },
                          ),
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
                      onTap: () {
                        context.push('/profile');
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildSettingItem(
                      context,
                      icon: Icons.lock_outline,
                      title: 'PIN Kod',
                      subtitle: 'PIN kod o\'rnatish va o\'zgartirish',
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        final prefs = AppPreferencesService();
                        final hasPinCode = await prefs.hasPinCode();
                        
                        if (!context.mounted) return;
                        
                        if (hasPinCode) {
                          // PIN kod bor - o'zgartirish uchun avval tekshirish
                          final result = await context.push('/pin-verify');
                          if (result == true && context.mounted) {
                            // Verify muvaffaqiyatli - yangi PIN o'rnatish
                            context.push('/pin-setup');
                          }
                        } else {
                          // PIN kod yo'q - yangi o'rnatish
                          context.push('/pin-setup');
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    // Security Section - Biometric
                    if (_isBiometricAvailable) ...[
                      Text(
                        'Xavfsizlik',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSettingItem(
                        context,
                        icon: Icons.fingerprint,
                        title: _biometricType,
                        subtitle: _isBiometricEnabled 
                            ? 'Yoqilgan - ${_biometricType} yordamida kirish' 
                            : 'O\'chirilgan - Faqat PIN kod orqali kirish',
                        trailing: Switch(
                          value: _isBiometricEnabled,
                          onChanged: (value) async {
                            final prefs = AppPreferencesService();
                            final hasPinCode = await prefs.hasPinCode();
                            
                            if (!hasPinCode) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Avval PIN kod o\'rnating!',
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            if (value) {
                              // Yoqish - biometrik test qilish
                              try {
                                final authenticated = await _biometricService.authenticate(
                                  localizedReason: 'Biometrik autentifikatsiyani yoqish uchun tasdiqlang',
                                );

                                if (authenticated) {
                                  await prefs.setBiometricEnabled(true);
                                  setState(() {
                                    _isBiometricEnabled = true;
                                  });
                                  
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '$_biometricType muvaffaqiyatli yoqildi',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Autentifikatsiya bekor qilindi',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Xatolik yuz berdi: $e',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } else {
                              // O'chirish
                              await prefs.setBiometricEnabled(false);
                              setState(() {
                                _isBiometricEnabled = false;
                              });
                              
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '$_biometricType o\'chirildi',
                                  ),
                                  backgroundColor: Colors.grey,
                                ),
                              );
                            }
                          },
                          activeColor: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 16),
                    // _buildSettingItem(
                    //   context,
                    //   icon: Icons.security,
                    //   title: 'Xavfsizlik',
                    //   subtitle: 'Parol va ruxsatlar',
                    //   trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    //   onTap: () {},
                    // ),
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
