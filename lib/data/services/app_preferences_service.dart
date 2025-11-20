import 'package:shared_preferences/shared_preferences.dart';

class AppPreferencesService {
  static const String _hasCompletedOnboardingKey = 'has_completed_onboarding';
  static const String _userNameKey = 'user_name';
  static const String _lastLoginDateKey = 'last_login_date';

  static final AppPreferencesService _instance =
      AppPreferencesService._internal();

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  AppPreferencesService._internal();

  factory AppPreferencesService() {
    return _instance;
  }

  // Initialize preferences
  Future<void> initialize() async {
    if (!_isInitialized) {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
    }
  }

  // Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding() async {
    await _ensureInitialized();
    return _prefs.getBool(_hasCompletedOnboardingKey) ?? false;
  }

  // Mark onboarding as completed
  Future<void> setOnboardingCompleted() async {
    await _ensureInitialized();
    await _prefs.setBool(_hasCompletedOnboardingKey, true);
  }

  // Get saved user name
  Future<String?> getUserName() async {
    await _ensureInitialized();
    return _prefs.getString(_userNameKey);
  }

  // Save user name
  Future<void> setUserName(String name) async {
    await _ensureInitialized();
    await _prefs.setString(_userNameKey, name);
  }

  // Get last login date
  Future<String?> getLastLoginDate() async {
    await _ensureInitialized();
    return _prefs.getString(_lastLoginDateKey);
  }

  // Save last login date
  Future<void> setLastLoginDate(String date) async {
    await _ensureInitialized();
    await _prefs.setString(_lastLoginDateKey, date);
  }

  // Clear all preferences
  Future<void> clearAll() async {
    await _ensureInitialized();
    await _prefs.clear();
  }

  // Reset onboarding flag
  Future<void> resetOnboarding() async {
    await _ensureInitialized();
    await _prefs.remove(_hasCompletedOnboardingKey);
  }

  // Ensure preferences are initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
}
