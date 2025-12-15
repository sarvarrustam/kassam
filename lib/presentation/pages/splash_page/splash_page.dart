import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kassam/data/services/api_service.dart';
import 'package:kassam/data/services/app_preferences_service.dart';
import 'package:kassam/presentation/theme/app_colors.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Animatsiya sozlash
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // Animatsiyani boshlash
    _controller.forward();

    // Token va onboarding tekshirish
    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    // Animatsiya tugashini kutish
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    try {
      final prefs = AppPreferencesService();

      // Token va onboarding tekshirish
      final token = await prefs.getAuthToken();
      final hasCompleted = await prefs.hasCompletedOnboarding();
      final hasPinCode = await prefs.hasPinCode();

      if (!mounted) return;

      print(
        '🔐 PIN Check: hasPinCode=$hasPinCode, hasCompleted=$hasCompleted, token=${token != null}',
      );

      if (token != null && token.isNotEmpty && hasCompleted) {
        // Token bor - versiyani tekshirish

        // Hozirgi app versiyasini olish
        final packageInfo = await PackageInfo.fromPlatform();
        final versionParts = packageInfo.version.split('.');
        final currentVersion = int.tryParse(versionParts.first) ?? 1;

        print('📱 Current app version: $currentVersion');

        // Versiya tekshirishni API'dan qilish (real vaqtda)
        int? serverVersion;
        final apiService = ApiService();
        try {
          final response = await apiService.get(
            'Kassam/hs/KassamUrl/getUser',
            token: token,
          );

          print('📡 API Response: $response');

          // API response'dagi versiyani olish
          // Turli response structure'larni sinab ko'rish
          print('📊 Full response keys: ${response.keys.toList()}');
          print('📊 response[data]: ${response['data']}');
          print('📊 response[version]: ${response['version']}');

          if (response['data'] is Map && response['data']['version'] != null) {
            serverVersion = response['data']['version'] as int?;
            print('✅ Got version from response[data][version]: $serverVersion');
          } else if (response['version'] != null) {
            serverVersion = response['version'] as int?;
            print('✅ Got version from response[version]: $serverVersion');
          } else {
            print('⚠️ No version found in response');
          }

          print('🔍 Server version from API: $serverVersion');
          print(
            '🔗 Comparison: currentVersion ($currentVersion) < serverVersion ($serverVersion) = ${currentVersion < (serverVersion ?? 0)}',
          );

          if (serverVersion != null && currentVersion < serverVersion) {
            // Versiya eski - ogohlantirish sahifasiga
            print(
              '🔴 Version update required from API: $currentVersion < $serverVersion',
            );
            if (!mounted) return;
            context.go(
              '/version-update',
              extra: {
                'currentVersion': currentVersion,
                'requiredVersion': serverVersion,
              },
            );
            return;
          }
        } catch (e) {
          // API xatosi - davom etish
          print('⚠️ Version check error: $e');
        }

        if (!mounted) return;

        print('✅ Version check passed, navigating...');

        // PIN code statusini yana tekshirish (yangi o'rnatilgan bo'lishi mumkin)
        final currentPinStatus = await prefs.hasPinCode();
        print('🔐 PIN Check (after version): currentPinStatus=$currentPinStatus');

        // Versiya to'g'ri - davom etish
        if (currentPinStatus) {
          // PIN kod o'rnatilgan -> PIN verify sahifasiga
          print('🔐 PIN code bor, verify sahifasiga o\'tish');
          context.go('/pin-verify');
        } else {
          // PIN kod o'rnatilmagan -> To'g'ridan-to'g'ri home'ga
          print('⚠️ PIN code yo\'q, home sahifasiga o\'tish');
          context.go('/home');
        }
      } else if (hasCompleted) {
        // Onboarding tugagan lekin token yo'q -> Phone input'ga
        context.go('/phone-input');
      } else {
        // Onboarding tugamagan -> Entry'ga
        context.go('/entry');
      }
    } catch (e) {
      // Xatolik bo'lsa entry'ga
      if (mounted) {
        context.go('/entry');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryGreen, AppColors.primaryGreenLight],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo animatsiyasi
              ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 70,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // App nomi
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Kassam',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Tagline
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Shaxsiy Moliyani Boshqaring',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 60),
              // Loading indicator
              FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
