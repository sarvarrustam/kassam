# Kassam - Tez Bog'lanish (Quick Reference)

## 🎯 Eng Ko'p Ishlatiladigan Kodlar

### Theme Almashtirish
```dart
// Dark/Light mode toggle
context.read<ThemeBloc>().add(ToggleThemeEvent());

// Dark mode yoqlash
context.read<ThemeBloc>().add(SetThemeEvent(true));

// Light mode yoqlash
context.read<ThemeBloc>().add(SetThemeEvent(false));
```

### Navigation
```dart
// Keyingi sahifaga o'tish
context.go('/home');

// Extra data bilan o'tish
context.go('/sms-verification', extra: phoneNumber);

// Orqaga qaytish
context.pop();

// Boshidan boshlash
context.go('/entry');
```

### Colors Foydalanish
```dart
import 'package:kassam/presentation/theme/app_colors.dart';

// Asosiy ranglar
Color primary = AppColors.primaryGreen;
Color accent = AppColors.accentBlue;
Color error = AppColors.errorRed;

// Text ranglar
Color text = AppColors.textPrimary;
Color hint = AppColors.textSecondary;
```

### Custom Button
```dart
ElevatedButton(
  onPressed: () {},
  child: const Text('Boshlash'),
)
```

### Custom Input
```dart
TextField(
  decoration: InputDecoration(
    hintText: 'Ismingizni kiriting',
    prefixIcon: const Icon(Icons.person),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
)
```

### Gradient Card
```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.primaryGreen,
        AppColors.primaryGreenLight,
      ],
    ),
    borderRadius: BorderRadius.circular(16),
  ),
  child: Padding(
    padding: const EdgeInsets.all(20),
    child: Text('Your content'),
  ),
)
```

---

## 📂 Fayllar Joylashtirish

### Yangi Sahifa Qo'shish
```
lib/presentation/pages/new_page.dart
```

### Yangi BLoC Qo'shish
```
lib/arch/bloc/new_bloc.dart
```

### Yangi Model Qo'shish
```
lib/data/models/new_model.dart
```

### Yangi Service Qo'shish
```
lib/data/services/new_service.dart
```

---

## 🔄 Eng Tez Ko'rinishlar

### Empty State
```dart
Container(
  decoration: BoxDecoration(
    border: Border.all(color: AppColors.borderGrey),
    borderRadius: BorderRadius.circular(12),
  ),
  padding: const EdgeInsets.all(32),
  child: Center(
    child: Column(
      children: [
        Icon(Icons.history, size: 48, color: AppColors.textSecondary),
        const SizedBox(height: 16),
        Text('Hali ma\'lumot yo\'q'),
      ],
    ),
  ),
)
```

### Settings Item
```dart
Container(
  decoration: BoxDecoration(
    border: Border.all(color: AppColors.borderGrey),
    borderRadius: BorderRadius.circular(12),
  ),
  padding: const EdgeInsets.all(16),
  child: Row(
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.settings, color: AppColors.primaryGreen),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title', style: Theme.of(context).textTheme.bodyLarge),
            Text('Subtitle', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ],
  ),
)
```

### Gradient Header
```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.primaryGreen,
        AppColors.primaryGreenLight,
      ],
    ),
    borderRadius: const BorderRadius.only(
      bottomLeft: Radius.circular(24),
      bottomRight: Radius.circular(24),
    ),
  ),
  padding: const EdgeInsets.all(24),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Title', style: Theme.of(context).textTheme.displayMedium?.copyWith(
        color: Colors.white,
      )),
    ],
  ),
)
```

---

## 🎨 Spacing Reference

```dart
const SizedBox(height: 8);   // Kichik bo'sh joy
const SizedBox(height: 16);  // Oddiy bo'sh joy
const SizedBox(height: 24);  // Katta bo'sh joy
const SizedBox(height: 32);  // Juda katta bo'sh joy

// Gorizontal
const SizedBox(width: 8);
const SizedBox(width: 16);
const SizedBox(width: 24);
```

---

## 🔌 Text Styles

```dart
// Katta sarlavha
Theme.of(context).textTheme.displayLarge

// Asosiy sarlavha
Theme.of(context).textTheme.headlineSmall

// Tuman sarlavha
Theme.of(context).textTheme.titleLarge

// Asosiy matn
Theme.of(context).textTheme.bodyLarge

// Kichik matn
Theme.of(context).textTheme.bodySmall
```

---

## 🎭 Icon Reference (Eng Kop Ishlatiladigan)

```dart
Icons.home              // Bosh
Icons.home_outlined     // Bosh (chiziq)

Icons.person            // Shaxs
Icons.person_outline    // Shaxs (chiziq)

Icons.settings          // Sozlamalar
Icons.settings_outlined // Sozlamalar (chiziq)

Icons.brightness_4      // Tun rejimi
Icons.brightness_7      // Kun rejimi

Icons.arrow_forward_ios // O'ng strelka
Icons.arrow_back        // Chap strelka

Icons.check             // Tasdiqlamalash
Icons.close             // Bekor qilish

Icons.add               // Qo'shish
Icons.remove            // O'chirish

Icons.wallet            // Hamyon
Icons.money             // Pul
Icons.trending_up       // Ko'tarilish
Icons.trending_down     // Tushish

Icons.phone             // Telefon
Icons.email             // Email
Icons.lock              // Qulfli
Icons.visibility        // Ko'rinish
Icons.visibility_off    // Ko'rinmaydi
```

---

## 📦 Deployment Checklist

- [ ] Barcha errors ochirilgan
- [ ] Barcha warnings ochirilgan
- [ ] Dark mode test qilingan
- [ ] Navigation test qilingan
- [ ] TextField validation test qilingan
- [ ] Button onPressed funksiyalar test qilingan
- [ ] Images va assetlar qo'shilgan
- [ ] versioning yangilangan
- [ ] App name o'zgartirilgan
- [ ] App icon o'zgartirilgan

---

## 🚀 Release Bo'limi

### Build APK (Android)
```bash
flutter build apk --release
```

### Build iOS
```bash
flutter build ios --release
```

### Build Web
```bash
flutter build web --release
```

---

## 💾 Git Komandalar

```bash
# Yangi branch
git checkout -b feature/new-feature

# Commit
git commit -m "feat: yangi sahifa qo'shish"

# Push
git push origin feature/new-feature

# Pull Request yaratish (GitHub da)
```

---

## 🐛 Debug Tips

```dart
// Console ga chiqarish
print('Debug message');

// Structured logging
debugPrint('Debug message');

// Widget tree ko'rish
debugPrintWidgetBuilder = true;

// Frame info
debugPrintBeginFrameBanner = true;
debugPrintEndFrameBanner = true;
```

---

## 📱 Responsive Design

```dart
// Ekran o'lchami olish
MediaQuery.of(context).size.width
MediaQuery.of(context).size.height

// Responsive padding
padding: EdgeInsets.symmetric(
  horizontal: MediaQuery.of(context).size.width * 0.05,
)

// Mobile da responsive
if (MediaQuery.of(context).size.width < 600) {
  // Mobile layout
} else {
  // Tablet layout
}
```

---

**Tezroq ishlash uchun bu ma'lumotlardan foydalaning! 🚀**
