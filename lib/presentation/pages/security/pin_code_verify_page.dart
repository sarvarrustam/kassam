import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kassam/data/services/app_preferences_service.dart';
import 'package:kassam/presentation/theme/app_colors.dart';

class PinCodeVerifyPage extends StatefulWidget {
  const PinCodeVerifyPage({super.key});

  @override
  State<PinCodeVerifyPage> createState() => _PinCodeVerifyPageState();
}

class _PinCodeVerifyPageState extends State<PinCodeVerifyPage> {
  final _pinController = TextEditingController();
  String _errorMessage = '';
  int _attemptCount = 0;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _onNumberPressed(String number) {
    setState(() {
      _errorMessage = '';
      if (_pinController.text.length < 4) {
        _pinController.text += number;
        if (_pinController.text.length == 4) {
          _verifyPin();
        }
      }
    });
  }

  void _onDeletePressed() {
    setState(() {
      _errorMessage = '';
      if (_pinController.text.isNotEmpty) {
        _pinController.text =
            _pinController.text.substring(0, _pinController.text.length - 1);
      }
    });
  }

  Future<void> _verifyPin() async {
    final prefs = AppPreferencesService();
    final savedPin = await prefs.getPinCode();

    if (_pinController.text == savedPin) {
      // PIN to'g'ri
      if (mounted) {
        context.go('/home');
      }
    } else {
      // PIN xato
      setState(() {
        _attemptCount++;
        _errorMessage = 'Noto\'g\'ri PIN kod. Qayta urinib ko\'ring.';
        _pinController.clear();
      });

      // 3 marta noto'g'ri kiritsa
      if (_attemptCount >= 3) {
        _showTooManyAttemptsDialog();
      }
    }
  }

  void _showTooManyAttemptsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Juda ko\'p urinish'),
        content: const Text(
          'PIN kod 3 marta noto\'g\'ri kiritildi. Iltimos, qayta tizimga kiring.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final prefs = AppPreferencesService();
              await prefs.clearAuthToken();
              if (mounted) {
                context.go('/phone-input');
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryGreen.withOpacity(0.1),
              AppColors.primaryGreenLight.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryGreen,
                      AppColors.primaryGreenLight,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.lock,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              // Title
              Text(
                'Xush kelibsiz!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'PIN kodni kiriting',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 48),
              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < _pinController.text.length
                          ? AppColors.primaryGreen
                          : Colors.grey.shade300,
                      border: Border.all(
                        color: index < _pinController.text.length
                            ? AppColors.primaryGreen
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Error message
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 8),
              // Attempts
              if (_attemptCount > 0)
                Text(
                  'Urinish: $_attemptCount/3',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              const Spacer(),
              // Number pad
              _buildNumberPad(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          _buildNumberRow(['1', '2', '3']),
          const SizedBox(height: 16),
          _buildNumberRow(['4', '5', '6']),
          const SizedBox(height: 16),
          _buildNumberRow(['7', '8', '9']),
          const SizedBox(height: 16),
          _buildNumberRow(['', '0', 'delete']),
        ],
      ),
    );
  }

  Widget _buildNumberRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((number) {
        if (number.isEmpty) {
          return const SizedBox(width: 80, height: 80);
        }
        if (number == 'delete') {
          return _buildNumberButton(
            onPressed: _onDeletePressed,
            child: const Icon(
              Icons.backspace_outlined,
              color: AppColors.primaryGreen,
              size: 28,
            ),
          );
        }
        return _buildNumberButton(
          onPressed: () => _onNumberPressed(number),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryGreen,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNumberButton({
    required VoidCallback onPressed,
    required Widget child,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
