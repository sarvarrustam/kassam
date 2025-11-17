# 🚀 Kassam - Tezkor Boshlash Qo'llanmasi

## ⚡ 5 Daqiqada Boshlash

### 1️⃣ **Paketlarni Yuklab Olish** (30 soniya)
```bash
cd e:\Projects\kassam
flutter pub get
```

### 2️⃣ **Dasturni Ishga Tushirish** (1 daqiqa)
```bash
flutter run
```

### 3️⃣ **Dasturni Sinab Ko'rish** (3 daqiqa)
Quyidagi oqimni sinab ko'ring:
- ✅ Entry Page → "Boshlash" tugmasi
- ✅ Phone Registration → "998 (99) 123 45 67" kiriting
- ✅ SMS Verification → "111111" kiriting
- ✅ Create User → Ma'lumot kiriting va "Akkaunt Yaratish"
- ✅ Home Page → Bottom Navigation bar orqali harikatlaning

---

## 🎯 Eng Muhim Fayllar

### 📱 Sahifalarni O'zgartirish
```
lib/presentation/pages/
├── entry_page.dart              ← Kirish sahifasi
├── home_page.dart               ← Asosiy dashboard
└── settings_page.dart           ← Dark/Light mode toggle
```

### 🎨 Ranglarni O'zgartirish
```
lib/presentation/theme/app_colors.dart
```

Misol:
```dart
static const Color primaryGreen = Color(0xFF1FB584); // 🟢 O'zgartirilishi mumkin
```

### 🌙 Dark/Light Mode Test Qilish
1. Settings sahifasiga boring
2. "Tungi Rejim" switchni yalpaytiring
3. Tema avtomatik o'zgaradi!

---

## 🛠️ Tezkor Sozlamalar

### Dark Mode Colorni O'zgartirish
**Fayl**: `lib/presentation/theme/app_theme.dart`
```dart
colorScheme: const ColorScheme.dark(
  primary: AppColors.primaryGreenLight,  // ← O'zgartirilishi mumkin
  // ...
)
```

### Entry Page Logoni O'zgartirish
**Fayl**: `lib/presentation/pages/entry_page.dart`
```dart
Icon(
  Icons.account_balance_wallet,  // ← O'zgartirilishi mumkin
  size: 60,
)
```

### Bottom Navigation Bar Ikonkalari
**Fayl**: `lib/presentation/routes/app_routes.dart`
```dart
BottomNavigationBarItem(
  icon: Icon(Icons.home_outlined),  // ← O'zgartirilishi mumkin
  label: 'Bosh',
)
```

---

## 📋 Har Bir Sahifaning Lokatsiyasi

| Sahifa | Fayl | Yo'l |
|--------|------|------|
| Kirish | entry_page.dart | /entry |
| Telefon | phone_registration_page.dart | /phone-input |
| SMS | sms_verification_page.dart | /sms-verification |
| Profil | create_user_page.dart | /create-user |
| Dashboard | home_page.dart | /home |
| Statistika | stats_page.dart | /stats |
| Byudjet | budget_page.dart | /budget |
| Sozlamalar | settings_page.dart | /settings |

---

## 🎨 Ranglar Ro'yxati

### Asosiy Ranglar
```dart
primaryGreen       = #1FB584  🟢 Yeşil (Daromad)
primaryGreenLight  = #4ECDC4  💚 Yorug' yashil (Aksent)
errorRed           = #E74C3C  🔴 Qizil (Xarajat)
warningOrange      = #FF9800  🟠 Orang (Ogohlantirish)
accentBlue         = #2196F3  🔵 Ko'k (Aksent)
```

### Matn Ranglari
```dart
textPrimary        = #212121  Qora (Asosiy)
textSecondary      = #757575  Griish (Ikkinchi)
```

---

## 🔍 Debugging Tips

### Debug Modeda Ishga Tushirish
```bash
flutter run --debug
```

### Release Modeda Ishga Tushirish
```bash
flutter run --release
```

### Hot Reload
```
Ctrl+S (Win) yoki Cmd+S (Mac)
```

### Hot Restart
```
Ctrl+Shift+F5 (Win)
```

### Errorlarni Ko'rish
```bash
flutter analyze
```

---

## 🧪 Test Qilish Checklist

- [ ] Entry page animatsiyasi ishlayaptimi?
- [ ] Telefon raqam validation ishlayaptimi?
- [ ] SMS timer 60 soniyadan boshlayaptimi?
- [ ] Create user sahifasida barcha fildlar ko'rinayaptimi?
- [ ] Home page balans kartasi gradient ko'rinayaptimi?
- [ ] Bottom navigation bosslanma ishga tushayaptimi?
- [ ] Settings dagi Dark mode switchini bosganida o'zgarayaptimi?
- [ ] Barcha matnlar Uzbek tilida ko'rinayaptimi?

---

## 📦 Foydalanilgan Kutubxonalar

```yaml
flutter_bloc: ^8.1.2       # State management
go_router: ^17.0.0         # Navigation
intl_phone_field: ^3.2.0   # Phone input
```

Boshqalar? `pubspec.yaml` ni ko'ring.

---

## 🆘 Agar Muammo Bo'lsa

### Muammo 1: "pubspec.yaml" yüklemə xətası
```bash
# Yechim:
flutter pub get
flutter pub upgrade
```

### Muammo 2: Dark mode o'zgarmasligi
```dart
// BlocBuilder ichida ishlatish:
BlocBuilder<ThemeBloc, ThemeState>(
  builder: (context, state) {
    return Switch(
      value: state.isDarkMode,
      onChanged: (value) {
        context.read<ThemeBloc>().add(ToggleThemeEvent());
      },
    );
  },
)
```

### Muammo 3: Navigation ishlashligi
```bash
# Router qo'sh-ld-q-d tekshirilishi:
flutter run --verbose
```

---

## 💾 Qo'shimcha Fayllar

- 📖 `README.md` - Asosiy dokumentatsiya
- 📋 `IMPLEMENTATION_GUIDE.md` - Kengaytirilgan qo'llanma
- 🗂️ `PROJECT_STRUCTURE.md` - Tuzilma
- 📊 `CREATED_SUMMARY.md` - Yaratilgan ishlar

---

## 🚀 Keyingi Bosqich

1. Backend API ni integratsiyalash
2. Database (Hive) ni o'rniga qo'yish
3. Firebase authentication
4. Unit testing
5. Google Play/App Store deployment

---

## 📞 Tezkor Bog'lanish

```
GitHub:     github.com/sarvarrustam/kassam
Email:      sarvarrustam@example.com
Telegram:   @sarvarrustam
```

---

## ✅ Done!

```
🎉 Shunday qilib:
✨ 8 ta sahifa yaratildi
🎨 Dark/Light tema o'rnatildi
🌍 Navigation sozlandi
📱 Mobile-first dizayn
🎯 Barcha komponentlar tayyor

Oylamatak o'ynash uchun tayyor!
```

---

**Maslahat**: 
> Dasturni sinab ko'rganingizdan so'ng,
> `lib/presentation/theme/app_colors.dart` da ranglarni 
> o'zingizning istegingizga moslang!

**Bugungi Sana**: 18-Noyabr, 2025
**Zamon**: ⏰ Tezkor boshlashga tayyor!

🚀 Boshlang! Muvaffaqiyatlar tilayb! 🙏✨
