# One-Time Entry - Quick Reference Card

## 🚀 What's New?

Entry flow shows **only once** → Then home page on every launch after.

---

## 📊 User Experience

```
FIRST TIME:
┌─────────────────────────────────────┐
│ Entry → Phone → SMS → Create → Home │
└─────────────────────────────────────┘
           (Full flow)

EVERY OTHER TIME:
┌────────────────────────────┐
│ App Starts → [Check Flag] → Home │
└────────────────────────────┘
        (Instant, no entry)
```

---

## 🔧 How It Works

| Step | File | Action |
|------|------|--------|
| 1️⃣ | `main.dart` | Initialize `AppPreferencesService()` |
| 2️⃣ | `app_routes.dart` | GoRouter checks `hasCompletedOnboarding()` |
| 3️⃣ | First Launch | Flag is `false` → Show entry flow |
| 4️⃣ | `create_user_page.dart` | User completes → Call `setOnboardingCompleted()` |
| 5️⃣ | Device Storage | Flag saved as `true` |
| 6️⃣ | Next Launch | Flag is `true` → Skip to home |

---

## 💾 Storage

**What's stored:**
```
Device Storage (SharedPreferences):
  • has_completed_onboarding: true/false
  • user_name: "Abdulaziz"
  • last_login_date: "2025-11-20T10:30:00.000Z"
```

**Where:**
- 🤖 Android: SharedPreferences
- 📱 iOS: UserDefaults
- 🌐 Web: LocalStorage

**Persists:**
- ✅ App restarts
- ✅ Device reboots
- ❌ App uninstall

---

## 📝 Code Snippets

### Check Status
```dart
final prefs = AppPreferencesService();
final isDone = await prefs.hasCompletedOnboarding();
print(isDone ? '✅ Entry done' : '❌ Entry needed');
```

### On Registration Complete
```dart
final prefs = AppPreferencesService();
await prefs.setUserName('Abdulaziz');
await prefs.setOnboardingCompleted();
context.go('/home');
```

### Reset (for testing)
```dart
await AppPreferencesService().resetOnboarding();
// Entry flow will show again on next launch
```

### Get Saved Name
```dart
final prefs = AppPreferencesService();
final name = await prefs.getUserName();
print('Welcome, $name!');
```

---

## 🧪 Testing

```bash
# Test 1: Fresh install shows entry
flutter clean && flutter run
→ See: Entry Page → Phone → SMS → Create User → Home

# Test 2: Restart skips entry
flutter run
→ See: Home Page (directly, no entry)

# Test 3: Reset to test again
# Add temp button in settings:
await AppPreferencesService().resetOnboarding();
context.go('/entry');
```

---

## 📁 Files Changed

```
✨ NEW:  lib/data/services/app_preferences_service.dart
✏️ EDIT: lib/main.dart
✏️ EDIT: lib/presentation/routes/app_routes.dart
✏️ EDIT: lib/presentation/pages/registration_pages/create_user_page.dart
📖 DOCS: ONE_TIME_ENTRY.md
📖 DOCS: ONE_TIME_ENTRY_SUMMARY.md
```

---

## ✅ Status

| Item | Status |
|------|--------|
| Compilation | ✅ 0 Errors |
| Warnings | ⚠️ 23 (non-blocking) |
| One-Time Entry | ✅ Working |
| Data Persistence | ✅ Working |
| Documentation | ✅ Complete |
| Production Ready | ✅ YES |

---

## 🎯 Common Tasks

### Use saved user name
```dart
final name = await AppPreferencesService().getUserName();
// Use 'name' in greeting or settings
```

### Add logout button
```dart
ElevatedButton(
  onPressed: () async {
    await AppPreferencesService().resetOnboarding();
    context.go('/entry');
  },
  child: Text('Logout'),
)
```

### Track login history
```dart
await AppPreferencesService()
  .setLastLoginDate(DateTime.now().toIso8601String());
```

### Debug onboarding status
```dart
print('Has completed: ${await AppPreferencesService().hasCompletedOnboarding()}');
print('User name: ${await AppPreferencesService().getUserName()}');
```

---

## 🔗 Architecture

```
                    MyApp
                     │
          [Initialize AppPreferencesService]
                     │
                   GoRouter
                     │
         ┌────────────┴────────────┐
         │                         │
    redirect() function            routes
         │
    [Check hasCompletedOnboarding()]
         │
    ┌────┴────┐
 false       true
    │         │
 Entry     Home
  Flow      Page
    │
    └──→ Create User Page
         [Call setOnboardingCompleted()]
         [Save to Device Storage]
         └──→ Home Page
```

---

## 📚 Read More

For detailed information, see:
- **ONE_TIME_ENTRY.md** - Complete technical guide
- **ONE_TIME_ENTRY_SUMMARY.md** - Full summary with examples

---

**Version:** 1.0  
**Date:** November 20, 2025  
**Status:** ✅ Production Ready

