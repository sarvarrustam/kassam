import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../bloc/auth_bloc.dart';

class PhoneRegistrationPage extends StatefulWidget {
  const PhoneRegistrationPage({super.key});

  @override
  State<PhoneRegistrationPage> createState() => _PhoneRegistrationPageState();
}

class _PhoneRegistrationPageState extends State<PhoneRegistrationPage> {
  final TextEditingController _phoneController = TextEditingController();
  String _completePhone = '';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _continueWithPhone() {
    if (_completePhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Iltimos, telefon raqamini kiriting')),
      );
      return;
    }

    // BLoC event yuborish
    context.read<AuthBloc>().add(AuthRequestedSmsCode(_completePhone));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSmsCodeSent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('SMS kod yuborildi'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/sms-verification', extra: _completePhone);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 6),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Telefon Raqam'), elevation: 0),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 100),
                Center(
                  child: Text(
                    'Telefon Raqamingiz',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Ro\'yxatdan o\'tish uchun telefon raqamini kiriting.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 50),
                IntlPhoneField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Telefon Raqami',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                  initialCountryCode: 'UZ',
                  onChanged: (phone) {
                    _completePhone = phone.completeNumber;
                  },
                ),
                const SizedBox(height: 32),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;
                    
                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _continueWithPhone,
                        child: isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Davom Etish',
                                style: TextStyle(fontSize: 18),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => context.go('/'),
                        child: Text(
                          'Mehmon sifatida kirish',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
