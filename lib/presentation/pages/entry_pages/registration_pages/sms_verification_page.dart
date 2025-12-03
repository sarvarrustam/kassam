import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../bloc/auth_bloc.dart';

class SmsVerificationPage extends StatefulWidget {
  final String phoneNumber;

  const SmsVerificationPage({required this.phoneNumber, super.key});

  @override
  State<SmsVerificationPage> createState() => _SmsVerificationPageState();
}

class _SmsVerificationPageState extends State<SmsVerificationPage> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  int _secondsLeft = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _secondsLeft--;
          if (_secondsLeft > 0) {
            _startTimer();
          } else {
            _canResend = true;
          }
        });
      }
    });
  }

  void _resendCode() {
    setState(() {
      _secondsLeft = 60;
      _canResend = false;
    });
    _startTimer();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Kod qayta yuborildi')));
  }

  void _verifyOtp() {
    final otp = _otpControllers.map((c) => c.text).join();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Iltimos, 6 ta raqam kiriting')),
      );
      return;
    }

    // BLoC event yuborish
    context.read<AuthBloc>().add(AuthVerifySmsCode(widget.phoneNumber, otp));
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        print('📱 SMS Verification State: $state');
        
        if (state is AuthVerifiedUserExists) {
         
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Xush kelibsiz!'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/home');
        } else if (state is AuthVerifiedUserNew) {
         
         
          context.go('/create-user', extra: widget.phoneNumber);
        } else if (state is AuthError) {
      
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('SMS Tasdiqlash'), elevation: 0),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 100),
                Center(
                  child: Text(
                    'Kodni Kiriting',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    '${widget.phoneNumber} raqamiga yuborilgan 6 xonali kodni kiriting',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    6,
                    (index) => SizedBox(
                      width: 50,
                      height: 60,
                      child: TextFormField(
                        controller: _otpControllers[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        autofocus: index == 0,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 5) {
                            FocusScope.of(context).nextFocus();
                          } else if (value.isEmpty && index > 0) {
                            FocusScope.of(context).previousFocus();
                          }
                        },
                        decoration: InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.borderGrey,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.borderGrey,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primaryGreen,
                              width: 2,
                            ),
                          ),
                        ),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;
                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _verifyOtp,
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
                                'Tasdiqlash',
                                style: TextStyle(fontSize: 18),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Center(
                  child: _canResend
                      ? GestureDetector(
                          onTap: _resendCode,
                          child: Text(
                            'Kodni Qayta Yuborish',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        )
                      : Column(
                          children: [
                            Text(
                              'Kod qayta yuborilgucha',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_secondsLeft}s',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.w600,
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
