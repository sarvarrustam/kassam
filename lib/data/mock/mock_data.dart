// lib/data/mock/mock_data.dart

class MockAuthData {
  // Telefon va OTP kodlari Map
  static const Map<String, String> _otpMap = {
    "998901234567": "1234", // Test raqami va kodi
    "998917654321": "5678",
    "998921234567": "9012",
  };

  /// Raqam bo'yicha OTP kodni qaytaradi
  static String? getOtpByPhone(String fullPhone) {
    // Faqat raqamlarni qoldirish
    String cleanPhone = fullPhone.replaceAll(RegExp(r'\D'), '');
    return _otpMap[cleanPhone];
  }

  /// Haqiqiy so'rovni simulyatsiya qilish - OTP jo'natish
  static Future<bool> sendOtpRequest(String fullPhone) async {
    // Kuting (server so'rovini simulyatsiya qilish)
    await Future.delayed(const Duration(milliseconds: 1500));

    // Faqat raqamlarni qoldirish
    String cleanPhone = fullPhone.replaceAll(RegExp(r'\D'), '');

    // Faqat ro'yxatdagilarga jo'natadi
    return _otpMap.containsKey(cleanPhone);
  }

  /// OTP kodni tekshirish
  static bool verifyOtpCode(String otp, String fullPhone) {
    String cleanPhone = fullPhone.replaceAll(RegExp(r'\D'), '');
    final correctOtp = _otpMap[cleanPhone];
    return correctOtp != null && correctOtp == otp;
  }
}
