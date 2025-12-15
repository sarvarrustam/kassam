import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kassam/data/services/app_preferences_service.dart';
import 'package:kassam/presentation/theme/app_colors.dart';

class PinCodeSetupPage extends StatefulWidget {
  const PinCodeSetupPage({super.key});

  @override
  State<PinCodeSetupPage> createState() => _PinCodeSetupPageState();
}

class _PinCodeSetupPageState extends State<PinCodeSetupPage> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _isConfirmStep = false;
  String _firstPin = '';
  String _errorMessage = '';

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _onNumberPressed(String number) {
    setState(() {
      _errorMessage = '';
      if (_isConfirmStep) {
        if (_confirmPinController.text.length < 4) {
          _confirmPinController.text += number;
          if (_confirmPinController.text.length == 4) {
            _verifyPin();
          }
        }
      } else {
        if (_pinController.text.length < 4) {
          _pinController.text += number;
          if (_pinController.text.length == 4) {
            _moveToConfirmStep();
          }
        }
      }
    });
  }

  void _onDeletePressed() {
    setState(() {
      _errorMessage = '';
      if (_isConfirmStep) {
        if (_confirmPinController.text.isNotEmpty) {
          _confirmPinController.text = _confirmPinController.text
              .substring(0, _confirmPinController.text.length - 1);
        }
      } else {
        if (_pinController.text.isNotEmpty) {
          _pinController.text =
              _pinController.text.substring(0, _pinController.text.length - 1);
        }
      }
    });
  }

  void _moveToConfirmStep() {
    setState(() {
      _firstPin = _pinController.text;
      _isConfirmStep = true;
    });
  }

  Future<void> _verifyPin() async {
    if (_confirmPinController.text == _firstPin) {
      // PIN mos keldi - saqlash
      final prefs = AppPreferencesService();
      await prefs.savePinCode(_firstPin);
      
      if (mounted) {
        // Home sahifasiga o'tish
        context.go('/home');
      }
    } else {
      // PIN mos kelmadi
      setState(() {
        _errorMessage = 'PIN kod mos kelmadi. Qaytadan kiriting.';
        _confirmPinController.clear();
      });
      
      // 1 soniyadan keyin birinchi qadamga qaytish
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isConfirmStep = false;
            _pinController.clear();
            _confirmPinController.clear();
            _firstPin = '';
            _errorMessage = '';
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPin = _isConfirmStep ? _confirmPinController.text : _pinController.text;
    
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
                  Icons.lock_outline,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              // Title
              Text(
                _isConfirmStep ? 'PIN kodni tasdiqlang' : 'PIN kod yarating',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _isConfirmStep
                    ? 'Yuqoridagi PIN kodni qayta kiriting'
                    : '4 xonali PIN kod kiriting',
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
                      color: index < currentPin.length
                          ? AppColors.primaryGreen
                          : Colors.grey.shade300,
                      border: Border.all(
                        color: index < currentPin.length
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
