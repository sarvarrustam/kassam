import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kassam/arch/cubit/auth_state.dart';
import 'package:kassam/data/mock/mock_data.dart';
import 'package:kassam/data/models/user_model.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthInitial());

  String? _currentPhone;

  /// Telefon raqamiga OTP kodni yuborish (Mock)
  Future<void> sendOtp(String phoneNumber) async {
    emit(const AuthLoading());

    // Mock data orqali telefon raqamini tekshirish
    bool success = await MockAuthData.sendOtpRequest(phoneNumber);

    if (success) {
      _currentPhone = phoneNumber;
      emit(OtpSent(phoneNumber));
    } else {
      emit(
        const AuthError(
          "Telefon raqami noto'g'ri. 998901234567, 998917654321, yoki 998921234567 ni kiriting.",
        ),
      );
    }
  }

  /// OTP kodni tasdiqlash
  Future<void> verifyOtp(String otp) async {
    emit(const AuthLoading());

    // Kichik delay qo'shamiz simulyatsiya qilish uchun
    await Future.delayed(const Duration(milliseconds: 800));

    if (_currentPhone != null &&
        MockAuthData.verifyOtpCode(otp, _currentPhone!)) {
      emit(OtpVerified(_currentPhone ?? ""));
    } else {
      emit(
        const AuthError(
          "OTP kodi noto'g'ri. Iltimos, tekshirting va qayta urinib ko'ring.",
        ),
      );
    }
  }

  /// Foydalanuvchini ro'yxatdan o'tkazish
  Future<void> registerUser(String name) async {
    emit(const AuthLoading());

    // Kichik delay qo'shamiz simulyatsiya qilish uchun
    await Future.delayed(const Duration(seconds: 2));

    if (_currentPhone != null && name.isNotEmpty) {
      final user = UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        phoneNumber: _currentPhone!,
      );

      emit(AuthSuccess(user));
    } else {
      emit(const AuthError("Ism-sharifni to'liq kiriting."));
    }
  }

  /// Auth holati ni reset qilish
  void resetAuth() {
    _currentPhone = null;
    emit(const AuthInitial());
  }
}
