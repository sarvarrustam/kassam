import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Check if device supports biometric authentication
  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      print('Error checking device support: $e');
      return false;
    }
  }

  /// Check if biometrics are enrolled (e.g., fingerprint or face registered)
  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (e) {
      print('Error checking biometrics: $e');
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Authenticate using biometrics
  Future<bool> authenticate({
    required String localizedReason,
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      final isSupported = await isDeviceSupported();
      final canCheck = await canCheckBiometrics();

      if (!isSupported || !canCheck) {
        return false;
      }

      return await _auth.authenticate(
        localizedReason: localizedReason,
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Biometrik autentifikatsiya',
            cancelButton: 'Bekor qilish',
            biometricHint: 'Barmoq izingizni qo\'ying',
            biometricNotRecognized: 'Tanilmadi',
            biometricRequiredTitle: 'Biometrik autentifikatsiya kerak',
            biometricSuccess: 'Muvaffaqiyatli',
            deviceCredentialsRequiredTitle: 'Qurilma autentifikatsiyasi kerak',
            deviceCredentialsSetupDescription: 'Qurilma autentifikatsiyasini sozlang',
            goToSettingsButton: 'Sozlamalarga o\'tish',
            goToSettingsDescription: 'Biometrik autentifikatsiya sozlanmagan',
          ),
          IOSAuthMessages(
            cancelButton: 'Bekor qilish',
            goToSettingsButton: 'Sozlamalarga',
            goToSettingsDescription: 'Face ID/Touch ID sozlanmagan',
            lockOut: 'Face ID/Touch ID o\'chirilgan',
          ),
        ],
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      print('Authentication error: $e');
      return false;
    }
  }

  /// Get biometric type name for display
  String getBiometricTypeName(List<BiometricType> types) {
    if (types.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (types.contains(BiometricType.fingerprint)) {
      return 'Barmoq izi';
    } else if (types.contains(BiometricType.iris)) {
      return 'Iris';
    } else if (types.contains(BiometricType.strong) || 
               types.contains(BiometricType.weak)) {
      return 'Biometrik';
    }
    return 'Biometrik autentifikatsiya';
  }
}
