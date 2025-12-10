import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AppPreferencesService {
  static const String _hasCompletedOnboardingKey = 'has_completed_onboarding';
  static const String _userNameKey = 'user_name';
  static const String _lastLoginDateKey = 'last_login_date';
  static const String _authTokenKey = 'auth_token';
  static const String _phoneNumberKey = 'phone_number';
  static const String _userDataKey = 'user_data';

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

  // Save auth token
  Future<void> setAuthToken(String token) async {
    await _ensureInitialized();
    await _prefs.setString(_authTokenKey, token);
  }

  // Get auth token
  Future<String?> getAuthToken() async {
    await _ensureInitialized();
    return _prefs.getString(_authTokenKey);
  }

  // Save phone number
  Future<void> setPhoneNumber(String phoneNumber) async {
    await _ensureInitialized();
    await _prefs.setString(_phoneNumberKey, phoneNumber);
  }

  // Get phone number
  Future<String?> getPhoneNumber() async {
    await _ensureInitialized();
    return _prefs.getString(_phoneNumberKey);
  }

  // Save user data (JSON)
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _ensureInitialized();
    final jsonString = jsonEncode(userData);
    await _prefs.setString(_userDataKey, jsonString);
  }

  // Get user data (JSON)
  Future<Map<String, dynamic>?> getUserData() async {
    await _ensureInitialized();
    final jsonString = _prefs.getString(_userDataKey);
    if (jsonString != null) {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    }
    return null;
  }

  // Clear user data
  Future<void> clearUserData() async {
    await _ensureInitialized();
    await _prefs.remove(_userDataKey);
  }

  // Ensure preferences are initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
}
