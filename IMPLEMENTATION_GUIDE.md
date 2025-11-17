# Kassam - Dastur Qo'llanmasi (Implementation Guide)

## 🎉 Loyiha Yaratilishi Tugallandi!

Sizning `Kassam` shaxsiy moliya boshqarish dasturi muvaffaqiyatli yaratildi va barcha sahifalar tayyor!

## 📋 Tugallangan Modul va Sahifalar

### ✅ 1. **Entry Flow (Kirish Oqimi)**

#### Entry Page (`entry_page.dart`)
- **Xususiyatlar:**
  - Animatsiyalangan logo va brend nomi
  - Gradient fon tasarifi
  - "Boshlash" tugmasi
  - Responsive design

**Ishlash:**
```
Entry Page → Boshlash tugmasi → Phone Registration Page
```

#### Phone Registration Page (`phone_registration_page.dart`)
- **Xususiyatlar:**
  - `intl_phone_field` orqali xalqaro telefon kiritish
  - Mamlakatni avtomatik tanlash
  - Loading state
  - Validatsiya

**Ishlash:**
```
Phone Registration → Davom Ettirish → SMS Verification Page
```

#### SMS Verification Page (`sms_verification_page.dart`)
- **Xususiyatlar:**
  - 6 ta raqamli OTP kiritish
  - 60 soniyali countdown taymer
  - Qayta yuborish funksiyasi
  - Auto-focus keypad

**Ishlash:**
```
SMS Verification → Tasdiqlash → Create User Page
```

#### Create User Page (`create_user_page.dart`)
- **Xususiyatlar:**
  - Ism va email kiritish
  - Profil rasimi ko'rsatish
  - Valyuta tanlash (UZS, USD, RUB, EUR)
  - Akkaunt yaratish

**Ishlash:**
```
Create User → Akkaunt Yaratish → Home Page
```

---

### ✅ 2. **Main Application (Asosiy Dastur)**

#### Home Page (`home_page.dart`)
- **Xususiyatlar:**
  - Greeting section (Assalomu alaikum)
  - Balans kartasi (gradient bilan)
  - Tezkor amallar (4 ta button):
    - 📤 Xarajat (Expense)
    - 📥 Daromad (Income)
    - 🔄 O'tkazma (Transfer)
    - ➕ Boshqa (Other)
  - So'nggi tranzaksiyalar bo'limi (empty state)

**UI Features:**
- Green gradient card
- Icon-based action buttons
- Clean typography

#### Stats Page (`stats_page.dart`)
- **Xususiyatlar:**
  - Oylik daromad ko'rsatish
  - Oylik xarajat ko'rsatish
  - Balans hisob-kitoblar
  - Kategoriya bo'yicha tahlil

#### Budget Page (`budget_page.dart`)
- **Xususiyatlar:**
  - Byudjet yaratish/boshqarish
  - Kategoriyalar bo'yicha byudjet
  - Progress indicators
  - Tips and suggestions

#### Settings Page (`settings_page.dart`)
- **Xususiyatlar:**
  - 🌙 **Tungi Rejim** - Dark/Light mode toggle
  - 🌐 **Til** - Interfeys tilini tanlash
  - 👤 **Profil** - Profilni tahrir qilish
  - 🔒 **Xavfsizlik** - Parol va ruxsatlar
  - 🔔 **Bildirishnomalar** - Push notifications
  - 📞 **Akkauntdan Chiqish** - Logout

---

### ✅ 3. **Theme va Styling**

#### App Colors (`app_colors.dart`)
- **Primary Colors:**
  - `primaryGreen` (#1FB584) - Daromad
  - `primaryGreenLight` (#4ECDC4) - Aksent
  
- **Secondary Colors:**
  - `errorRed` (#E74C3C) - Xarajat
  - `warningOrange` (#FF9800) - Ogohlantirish
  - `accentBlue` (#2196F3) - Qo'shimcha

- **Neutral Colors:**
  - `textPrimary`, `textSecondary`
  - `borderGrey`, `dividerGrey`

#### App Theme (`app_theme.dart`)
- **Light Theme:**
  - Yorug' fon va surfacelar
  - To'q matn ranglar
  - Material Design 3 colorScheme

- **Dark Theme:**
  - To'q fon va surfacelar
  - Oq matn ranglar
  - Optimized contrast

---

### ✅ 4. **State Management**

#### Theme BLoC (`theme_bloc.dart`)
- **Events:**
  - `ToggleThemeEvent` - Dark/Light mode almashtirish
  - `SetThemeEvent` - Aniq tema belgilash

- **States:**
  - `ThemeInitial` - Boshlang'ich holat
  - `ThemeChanged` - Tema o'zgargan

**Foydalanish:**
```dart
// Theme almashtirish
context.read<ThemeBloc>().add(ToggleThemeEvent());

// Dark mode yoqlish
context.read<ThemeBloc>().add(SetThemeEvent(true));
```

---

### ✅ 5. **Navigation Sistema**

#### GoRouter Setup (`app_routes.dart`)

**Route Struktur:**
```
/entry              → EntryPage
/phone-input        → PhoneRegistrationPage
/sms-verification   → SmsVerificationPage
/create-user        → CreateUserPage
/home               → HomePage (with Bottom Nav)
/stats              → StatsPage (with Bottom Nav)
/budget             → BudgetPage (with Bottom Nav)
/settings           → SettingsPage (with Bottom Nav)
```

**RootLayout (ShellRoute):**
- Bottom Navigation Bar
- AppBar
- Child routing

---

## 🎨 UI/UX Xususiyatlar

### Design System
- ✅ Material Design 3 (useMaterial3: true)
- ✅ Rounded corners (12-16dp BorderRadius)
- ✅ Gradient backgrounds
- ✅ Consistent spacing (8dp grid system)
- ✅ Smooth animations

### Colors
- ✅ Gradient cards (Green)
- ✅ Icon-based actions
- ✅ Status colors (Success, Error, Warning)
- ✅ Dark mode support

### Typography
- ✅ displayLarge - Katta sarlavhalar
- ✅ headlineSmall - Asosiy sarlavhalar
- ✅ bodyLarge/Medium - Matn
- ✅ Consistent font sizes

---

## 🚀 Ishga Tushirish

### 1. Loyihani Tayyorlash
```bash
cd e:\Projects\kassam
flutter pub get
```

### 2. Dasturni Qo'shish
```bash
# Android
flutter run

# iOS
flutter run -d <device_id>

# Web
flutter run -d chrome
```

### 3. Hot Reload
```bash
# Dastur ishga tushgandan so'ng, `r` tugmasi bilan reload qiling
r
```

---

## 📱 Sahifalar O'rtasida Harakat Qilish

### Programmatik Navigation
```dart
// Keyingi sahifaga o'tish (extra data bilan)
context.go('/sms-verification', extra: phoneNumber);

// Orqaga qaytish
context.pop();

// Boshidan boshlash (entry page)
context.go('/entry');
```

---

## 🔧 Customize Qilish Bo'yicha Maslahatlar

### 1. Ranglarni O'zgartirish
```dart
// lib/presentation/theme/app_colors.dart
static const Color primaryGreen = Color(0xFF1FB584); // Shu rangni o'zgartiring
```

### 2. Matn Stillarini O'zgartirish
```dart
// lib/presentation/theme/app_theme.dart
textTheme: const TextTheme(
  displayLarge: TextStyle(
    fontSize: 32,  // O'zgartirilgan o'lcham
    fontWeight: FontWeight.bold,
  ),
```

### 3. Yangi Sahifa Qo'shish
```dart
// 1. Yangi sahifa yarating: lib/presentation/pages/new_page.dart
class NewPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(...);
  }
}

// 2. app_routes.dart da rout qo'shing
GoRoute(
  path: '/new-page',
  builder: (context, state) => const NewPage(),
),
```

### 4. API Integration
```dart
// Hozirgi: Future.delayed (Mock)
// Kelajakda: http, dio, yoki retrofit paketi
```

---

## 📊 Dastur Arkitekturasi

```
lib/
├── main.dart                    # BLoC Provider setup
├── arch/
│   └── bloc/
│       └── theme_bloc.dart     # Theme management
├── presentation/
│   ├── pages/
│   │   ├── entry_page.dart
│   │   ├── phone_registration_page.dart
│   │   ├── sms_verification_page.dart
│   │   ├── create_user_page.dart
│   │   ├── home_page.dart
│   │   ├── stats_page.dart
│   │   ├── budget_page.dart
│   │   └── settings_page.dart
│   ├── routes/
│   │   └── app_routes.dart     # GoRouter setup
│   └── theme/
│       ├── app_colors.dart
│       └── app_theme.dart
├── data/
│   ├── models/
│   ├── repositories/
│   └── services/
└── business/
    └── bloc/
```

---

## 🎯 Keyingi Qadamlar (Next Steps)

### Immediate (1-2 hafta)
- [ ] Backend API integratsiyasi
- [ ] Haqiqiy autentifikatsiya (Firebase yoki custom)
- [ ] Ma'lumot bazasi (SQLite yoki Supabase)
- [ ] Tranzaksiya log qilish

### Short Term (2-4 hafta)
- [ ] Grafiklar va diagrammalar (charts package)
- [ ] CSV export funksiyasi
- [ ] Push notifications
- [ ] Oflayn mode

### Medium Term (1-3 oy)
- [ ] Multi-currency support
- [ ] Budget alerts
- [ ] Recurring transactions
- [ ] Categories customization

### Long Term (3+ oy)
- [ ] Machine learning tavsiyalari
- [ ] Social sharing
- [ ] Web version
- [ ] Desktop apps (Windows, macOS, Linux)

---

## ⚠️ Muhim Eslatmalar

### State Management
- Theme state `BLoC` orqali boshqariladi
- Boshqa data uchun `Provider` yoki `Riverpod` qo'shish tavsiyalanadgan

### Performance
- `SingleChildScrollView` dan o'zgaruvchi ro'yxatlar uchun `ListView` dan foydalaning
- Rasmlarni cache qilish
- Network calls uchun timeout belgilang

### Security
- Parollarni plain text da saqlamang
- API keys `.env` faylida saqlang
- Sensitive data uchun encryption foydalaning

### Testing
- Unit tests `test/` papkasida
- Widget tests `test/` papkasida
- Integration tests `integration_test/` papkasida

---

## 📚 Foydalanilgan Paketlar

| Paket | Versiya | Maqsad |
|-------|---------|--------|
| flutter_bloc | 8.1.2 | State management |
| bloc | 8.1.4 | BLoC pattern |
| equatable | 2.0.5 | Equality |
| go_router | 17.0.0 | Navigation |
| intl_phone_field | 3.2.0 | Phone input |

---

## 🐛 Umumiy Muammolar va Yechimlar

### Muammo: Bottom Navigation rang almashtirilmaydi
**Yechim:** `bottomNavigationBarTheme` ni theme.dart da tekshiring

### Muammo: Text o'lchamlari turli
**Yechim:** `textTheme` dan foydalaning, inline style o'rniga

### Muammo: Dark mode almashtirilmaydi
**Yechim:** `MaterialApp` da `themeMode` ning `ThemeBloc` bilan bog'liqligini tekshiring

---

## 💡 Qo'shimcha Maslahatlar

1. **Code Organization**: Sahifalarni feature-based papkalarga ajrating
2. **Naming Convention**: `_private`, `camelCase`, `PascalCase` dan foydalaning
3. **Comments**: O'zbekcha va Inglizcha comments yozish
4. **Git**: Har bir feature uchun yangi branch yarating
5. **Testing**: TDD (Test-Driven Development) usulini qo'llang

---

## 📞 Support

Savollar bo'lsa, GitHub issues yoki pull requests qo'shing.

**Created:** November 18, 2025
**Language:** Dart/Flutter
**UI Framework:** Material Design 3

---

**Kassam dasturiga o'z hissalaringizni qo'shing va birga o'sib boraylik! 🚀**
