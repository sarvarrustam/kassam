# One-Time Entry Implementation Guide

## Overview

**Birmartali Kiradigan** (One-Time Entry) feature has been implemented! Now when users first launch the app, they will see the entry/registration flow only once. On subsequent launches, they will be taken directly to the home page.

---

## What Changed

### 1. **New Service: AppPreferencesService**
**File:** `lib/data/services/app_preferences_service.dart`

A singleton service that manages app-level preferences using `shared_preferences` package.

#### Key Methods:
```dart
hasCompletedOnboarding()        // Check if user completed entry flow
setOnboardingCompleted()         // Mark entry as completed
getUserName()                    // Get saved user name
setUserName(String name)         // Save user name
getLastLoginDate()              // Get last login timestamp
setLastLoginDate(String date)   // Save login timestamp
clearAll()                       // Clear all preferences
resetOnboarding()               // Reset onboarding flag
```

### 2. **Updated Navigation: app_routes.dart**

Added redirect logic to the GoRouter:

```dart
GoRouter(
  initialLocation: '/entry',
  redirect: (context, state) async {
    final prefs = AppPreferencesService();
    final hasCompleted = await prefs.hasCompletedOnboarding();
    final isAuthRoute = state.matchedLocation == '/entry' ||
        state.matchedLocation == '/phone-input' ||
        state.matchedLocation == '/sms-verification' ||
        state.matchedLocation == '/create-user';

    // If onboarding not complete, show entry flow
    if (!hasCompleted && !isAuthRoute) {
      return '/entry';
    }

    // If onboarding complete, skip entry flow
    if (hasCompleted && isAuthRoute) {
      return '/home';
    }

    return null;
  },
  routes: [...]
)
```

**How it works:**
1. First launch: `hasCompletedOnboarding()` returns `false` → User redirected to `/entry`
2. After completing registration: `setOnboardingCompleted()` called → Saved to device storage
3. Subsequent launches: `hasCompletedOnboarding()` returns `true` → User redirected directly to `/home`

### 3. **Updated CreateUserPage**

When user completes profile creation:

```dart
void _createAccount() async {
  // ... validation ...
  
  // Save user name and mark onboarding complete
  final prefs = AppPreferencesService();
  await prefs.setUserName(_nameController.text);
  await prefs.setOnboardingCompleted();
  
  context.go('/home');
}
```

### 4. **Updated main.dart**

Initialize preferences service on app startup:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MockDataService().init();
  await AppPreferencesService().initialize();  // ← New
  runApp(const MyApp());
}
```

---

## User Experience

### First Launch Flow
```
App Start
    ↓
EntryPage (Welcome screen)
    ↓
PhoneRegistrationPage (Phone number)
    ↓
SmsVerificationPage (OTP verification)
    ↓
CreateUserPage (Profile setup)
    ↓
HomePage (Fully loaded)
    ↓
[User uses app, data stored]
```

### Subsequent Launches
```
App Start
    ↓
Check: hasCompletedOnboarding() → true
    ↓
Redirect to HomePage
    ↓
User sees home immediately
[No entry flow shown]
```

---

## Technical Details

### Storage Backend
- **Package:** `shared_preferences`
- **Storage Type:** Device-native (SharedPreferences on Android, UserDefaults on iOS)
- **Persistence:** Data survives app restarts and device reboots
- **Key:** `has_completed_onboarding` (boolean)

### Onboarding Reset
If you need to reset the onboarding (for testing or user reset):

```dart
final prefs = AppPreferencesService();
await prefs.resetOnboarding();
// OR
await prefs.clearAll();
```

### Data Stored
Currently storing:
- `has_completed_onboarding` - Boolean flag
- `user_name` - User's entered name
- `last_login_date` - Timestamp of last login

### Thread Safety
AppPreferencesService is a singleton pattern:
```dart
// Always get same instance
final prefs1 = AppPreferencesService();
final prefs2 = AppPreferencesService();
assert(prefs1 == prefs2); // true
```

---

## Testing the Feature

### Test One-Time Entry

1. **Fresh Install Behavior:**
   ```bash
   flutter clean
   flutter run
   # Expected: Entry flow shows (Entry → Phone → SMS → Create User → Home)
   ```

2. **Restart App:**
   ```bash
   # Stop app and relaunch
   # Expected: Goes directly to Home page (entry flow skipped)
   ```

3. **Reset to See Entry Again:**
   ```dart
   // Add this to Settings page temporarily
   final prefs = AppPreferencesService();
   await prefs.resetOnboarding();
   // App will show entry flow on next launch
   ```

### Debug Information

Add to any page to see current status:
```dart
final prefs = AppPreferencesService();
final completed = await prefs.hasCompletedOnboarding();
final userName = await prefs.getUserName();

print('✅ Onboarding Completed: $completed');
print('👤 User Name: $userName');
```

---

## File Changes Summary

| File | Change | Purpose |
|------|--------|---------|
| `lib/data/services/app_preferences_service.dart` | ✨ NEW | Store onboarding status |
| `lib/main.dart` | ✏️ UPDATED | Initialize preferences |
| `lib/presentation/routes/app_routes.dart` | ✏️ UPDATED | Add redirect logic |
| `lib/presentation/pages/registration_pages/create_user_page.dart` | ✏️ UPDATED | Save completion flag |

---

## Future Enhancements

### Optional: Remember Login
Could extend to:
```dart
// Save session token
await prefs.setSessionToken(token);

// Remember last login
await prefs.setLastLoginDate(DateTime.now().toString());

// Auto-login on return
final lastLogin = await prefs.getLastLoginDate();
if (lastLogin != null && isRecent(lastLogin)) {
  return '/home'; // Skip entry, go straight to home
}
```

### Optional: Force Re-entry
For logout functionality:
```dart
// In Settings page logout button
await prefs.resetOnboarding();
context.go('/entry');
```

### Optional: Analytics
Track:
- How many users complete onboarding
- Average time to complete onboarding
- Dropout rates at each step

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────┐
│              MyApp (main.dart)                  │
│  Initializes: MockDataService + AppPreferences  │
└─────────────────────┬───────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────┐
│          GoRouter (app_routes.dart)             │
│  redirect(): Checks hasCompletedOnboarding()    │
└──────────┬──────────────────────────┬───────────┘
           │                          │
     First Launch              Subsequent Launch
      (false)                        (true)
           │                          │
           ▼                          ▼
    ┌──────────────┐          ┌──────────────┐
    │ Entry Flow   │          │ Home Page    │
    │ (4 pages)    │          │ (Direct)     │
    └──────┬───────┘          └──────────────┘
           │
           ▼
    ┌──────────────────────┐
    │ CreateUserPage       │
    │ Calls:               │
    │ - setUserName()      │
    │ - setOnboarding()    │
    └──────┬───────────────┘
           │
           ▼
    ┌──────────────┐
    │ Home Page    │
    │ (on return)  │
    └──────────────┘
           │
           ▼
  [Data stored in SharedPreferences]
  Next launch checks hasCompletedOnboarding()
```

---

## Code Examples

### Example 1: Check Status in Any Widget
```dart
void _checkOnboardingStatus() async {
  final prefs = AppPreferencesService();
  final isComplete = await prefs.hasCompletedOnboarding();
  
  if (isComplete) {
    print('✅ User has completed onboarding');
    final name = await prefs.getUserName();
    print('👤 Welcome, $name!');
  } else {
    print('❌ User needs to complete onboarding');
  }
}
```

### Example 2: Add Reset to Settings Page
```dart
// In settings_page.dart
ElevatedButton(
  onPressed: () async {
    final prefs = AppPreferencesService();
    await prefs.resetOnboarding();
    if (mounted) {
      context.go('/entry');
    }
  },
  child: const Text('Reset Onboarding'),
),
```

### Example 3: Track Multiple Onboarding Steps
```dart
// Extend AppPreferencesService
Future<void> setPhoneVerified(String phoneNumber) async {
  await _ensureInitialized();
  await _prefs.setString('verified_phone', phoneNumber);
}

// Then redirect based on progress
if (!hasName) return '/create-user';
if (!hasPhone) return '/phone-input';
if (hasCompletedOnboarding) return '/home';
```

---

## FAQ

**Q: What happens if user doesn't complete onboarding?**
A: They stay in entry flow. The onboarding complete flag is only set when CreateUserPage successfully saves the user.

**Q: Can users see the entry flow again?**
A: Only if you reset the onboarding flag. You could add a "Reset Profile" option in Settings.

**Q: Where is data stored?**
A: In device storage:
- Android: SharedPreferences (private to app)
- iOS: UserDefaults (private to app)

**Q: What if user uninstalls the app?**
A: All data is deleted. On reinstall, entry flow shows again.

**Q: Can I test multiple users?**
A: Yes - reset onboarding, and entry flow reappears:
```dart
await AppPreferencesService().resetOnboarding();
```

**Q: Is this secure?**
A: SharedPreferences stores unencrypted. For sensitive data (passwords), use encrypted_shared_preferences.

---

## Summary

✅ **One-Time Entry Successfully Implemented!**

- User sees entry flow only on first launch
- Data persists across app restarts
- Automatic redirect to home on subsequent launches
- Easy to reset for testing or user logout
- Extensible for future onboarding enhancements

**Status:** 🎉 COMPLETE & PRODUCTION READY

