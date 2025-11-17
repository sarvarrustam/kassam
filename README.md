# Kassam - Shaxsiy Moliya Boshqarish Dasturi

Kassam - bu Uzbek tilida yozilgan, Flutter bilan yaratilgan shaxsiy moliya boshqarish dasturidir. Dastur sizga daromad, xarajat va byudjetni kuzatish imkoniyatini beradi.

## ✨ Asosiy Xususiyatlar

- 📱 **Zamonaviy Dizayn** - Material Design 3 bilan yaratilgan
- 🌙 **Tungi/Yorug' Rejim** - Tun va kun rejimida ishlash
- 📊 **Statistika** - Oyliq statistika va tahlil
- 💰 **Byudjet Boshqaruvi** - Oylik byudjet yaratish va kuzatish
- 🔐 **Xavfsiz Kirish** - SMS orqali ro'yxatdan o'tish
- 🎨 **Shaxsiylash** - Ranglarni va tuzlamalarni sozlash

## 📂 Papka Tuzilishi

```
lib/
├── main.dart                           # Asosiy dastur kirish nuqtasi
├── arch/
│   └── bloc/
│       └── theme_bloc.dart            # Tema boshqarish (Dark/Light mode)
├── presentation/
│   ├── pages/
│   │   ├── entry_page.dart            # Kirish sahifasi
│   │   ├── phone_registration_page.dart # Telefon raqam sahifasi
│   │   ├── sms_verification_page.dart  # SMS tasdiqlamalash sahifasi
│   │   ├── create_user_page.dart       # Foydalanuvchi yaratish sahifasi
│   │   ├── home_page.dart              # Asosiy sahifa (dashboard)
│   │   ├── stats_page.dart             # Statistika sahifasi
│   │   ├── budget_page.dart            # Byudjet sahifasi
│   │   └── settings_page.dart          # Sozlamalar sahifasi
│   ├── routes/
│   │   └── app_routes.dart             # GoRouter konfiguratsiyasi
│   └── theme/
│       ├── app_colors.dart             # Rang palitra
│       └── app_theme.dart              # Tema sozlamalari (Light/Dark)
```

## 🚀 Boshlash

### Talablar
- Flutter SDK: ^3.8.1
- Dart: Flutter bilan birga keladi

### Asosiy Qadamlar

1. **Loyihani Klonlash**
```bash
git clone https://github.com/sarvarrustam/kassam.git
cd kassam
```

2. **Paketlarni Yuklab Olish**
```bash
flutter pub get
```

3. **Dasturni Ishga Tushirish**
```bash
flutter run
```

## 📦 Foydalanilgan Paketlar

- **flutter_bloc** (^8.1.2) - State management uchun
- **bloc** (^8.1.4) - Business Logic Component
- **equatable** (^2.0.5) - Equality comparison uchun
- **go_router** (^17.0.0) - Navigation uchun
- **intl_phone_field** (^3.2.0) - Telefon raqam kiritish uchun

## 🎯 Sahifalarni Tushunish

### 1. Kirish Sahifasi (Entry Page)
- Dasturning birinchi sahifasi
- Animatsiyalangan dizayn
- "Boshlash" tugmasi bilan telefon raqamiga o'tadi

### 2. Telefon Raqam Sahifasi (Phone Registration)
- Telefon raqamni kirish
- Mamlakatni tanlash (`intl_phone_field` orqali)
- Validatsiya va yuborish

### 3. SMS Tasdiqlamalash (SMS Verification)
- 6 ta raqamli SMS kodni kiritish
- Qayta yuborish funksiyasi (60 soniyali taymer bilan)
- OTP tasdiqlamalash

### 4. Foydalanuvchi Yaratish (Create User)
- Ism va email kirish
- Rasm yuklash (interfeys tayyorlangan)
- Asosiy valyuta tanlash (UZS, USD, RUB, EUR)

### 5. Asosiy Sahifa (Home Page)
- Balans ko'rsatish (gradient kartasi bilan)
- Tezkor amallar (Xarajat, Daromad, O'tkazma, Boshqa)
- So'nggi tranzaksiyalar bo'limi

### 6. Statistika Sahifasi (Stats Page)
- Oylik daromad va xarajat
- Kategoriya bo'yicha tahlil
- Grafiklar va diagrammalar (tayyorlanmoqda)

### 7. Byudjet Sahifasi (Budget Page)
- Byudjet yaratish va boshqarish
- Kategoriyalar bo'yicha byudjet belgilash
- Oylik balans kuzatish

### 8. Sozlamalar Sahifasi (Settings)
- **Tungi Rejim** - Dark/Light mode almashtirish
- **Til** - Interfeys tilini tanlash
- **Profil** - Shaxsiy ma'lumotlarni tahrir qilish
- **Xavfsizlik** - Parol va ruxsatlar
- **Bildirishnomalar** - Bildirishnoma sozlamalari
- **Akkauntdan Chiqish** - Chiqish funksiyasi

## 🎨 Ranglar va Tema

### Asosiy Ranglar (App Colors)
- **Primary Green** (#1FB584) - Daromad va ijobiy amallar
- **Primary Green Light** (#4ECDC4) - Aksent ranglar
- **Error Red** (#E74C3C) - Xarajat va xatolar
- **Warning Orange** (#FF9800) - Ogohlantirish
- **Accent Blue** (#2196F3) - Qo'shimcha aksent

### Tema Sistema
- **Light Theme** - Kunduzi ishlatish uchun tayyorlangan
- **Dark Theme** - Tungi rejim, ko'zga yumshok

## 🔄 Navigation (Yo'naltirish)

```
Entry Page
    ↓
Phone Registration
    ↓
SMS Verification
    ↓
Create User
    ↓
Home Page ← (Bottom Navigation bilan)
├── Stats Page
├── Budget Page
└── Settings Page
```

## 🛠️ Theme BLoC Tushuntirish

```dart
// Theme almashtirish
context.read<ThemeBloc>().add(ToggleThemeEvent());

// Aniq tema belgilash
context.read<ThemeBloc>().add(SetThemeEvent(true)); // true = dark mode
```

## 📱 UI Components

### Custom Buttons
- **ElevatedButton** - Asosiy amallar uchun
- **OutlinedButton** - Ikkinchi darajali amallar uchun
- **TextButton** - Linklar va boshqa amallar

### Input Fields
- **TextField** - Oddiy matn kiritish
- **IntlPhoneField** - Telefon raqam kiritish
- **DropdownButton** - Variantlardan tanlash

### Cards va Containers
- **Custom Gradient Cards** - Tasvir va malumot ko'rsatish
- **Action Buttons** - Tezkor amallar
- **Setting Items** - Sozlamalar qatorlari

## 💾 Data Management

Hozirgi holatda dastur local state (BLoC) dan foydalanadi. Server integratsiyasi uchun:

```dart
// Future.delayed bilan simulate qilingan API calls
Future.delayed(const Duration(seconds: 2), () {
  // API response handler
});
```

## 🔧 Customize Qilish

### Ranglarni O'zgartirish
`lib/presentation/theme/app_colors.dart` faylini tahrir qiling

### Tema Sozlamalarini O'zgartirish
`lib/presentation/theme/app_theme.dart` faylini tahrir qiling

### Sahifalarni Qo'shish
1. `lib/presentation/pages/` da yangi fayl yarating
2. `app_routes.dart` da rout qo'shing
3. Bottom navigation da agar zarur bo'lsa icon qo'shing

## 📝 Loyiha Statusi

- ✅ **Tugallangan**
  - Kirish oqimi (Entry flow)
  - SMS tasdiqlamalash
  - Bottom navigation
  - Dark/Light mode
  - Bazaviy sahifalar

- 🔄 **Tayyorlanmoqda**
  - Backend integration
  - Haqiqiy ma'lumot boshqaruvi
  - Grafiklar va diagrammalar
  - Push notifications

## 📧 Bog'lanish

Agar savollar yoki takliflar bo'lsa:
- 📱 +998 (99) 123 45 67
- 📧 sarvarrustam@example.com

## 📄 Litsenziya

Bu loyiha MIT litsenziyasi ostida mavjuddir.

---

**Ochilgan:** November 2025
**Mualliflar:** Sarvar Rustam va Jamoasi

Kassam dasturiga ishtirok uchun rahmat! 🙏
