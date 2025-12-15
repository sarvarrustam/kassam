import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kassam/presentation/theme/app_colors.dart';

class VersionUpdateRequiredPage extends StatelessWidget {
  final int currentVersion;
  final int requiredVersion;

  const VersionUpdateRequiredPage({
    super.key,
    required this.currentVersion,
    required this.requiredVersion,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ogohlantirish icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.system_update_alt,
                size: 60,
                color: Colors.orange.shade700,
              ),
            ),

            const SizedBox(height: 32),

            // Sarlavha
            Text(
              'Yangilanish kerak',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 16),

            // Xabar
            Text(
              'Siz eski versiyadan foydalanyapsiz. Dasturni ishlatish uchun yangi versiyaga yangilanish zarur.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 32),

            // Versiya ma'lumotlari
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildVersionRow(
                    'Joriy versiya:',
                    'v$currentVersion',
                    Colors.red.shade700,
                  ),
                  const SizedBox(height: 12),
                  _buildVersionRow(
                    'Kerakli versiya:',
                    'v$requiredVersion',
                    Colors.green.shade700,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Dasturdan chiqish tugmasi
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Dasturdan chiqish
                  SystemNavigator.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Dasturdan chiqish',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Qo'shimcha ma'lumot
            Text(
              'Yangi versiyani Google Play Store yoki App Store\'dan yuklab oling',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionRow(String label, String version, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
        Text(
          version,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
