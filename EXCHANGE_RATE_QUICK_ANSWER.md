# 💱 Exchange Rate - Quick Reference

## 🎯 Your Question
```
"Dollirni kursini qaysi filda belgilayabsan?"
(Which file is the dollar exchange rate defined in?)
```

## ✅ Answer
```
FILE: lib/core/constants/exchange_rates.dart
RATE: 1 USD = 11,500 UZS
```

---

## 📍 File Location Diagram

```
PROJECT ROOT (e:\Projects\kassam\)
│
├── lib/
│   ├── core/
│   │   └── constants/
│   │       └── exchange_rates.dart  ← 💱 EXCHANGE RATE HERE
│   │
│   └── presentation/
│       └── pages/
│           ├── home_page/
│           │   └── home_page.dart   (uses the rate)
│           └── stats_page.dart
│
├── android/
├── ios/
└── pubspec.yaml
```

---

## 🔍 What's in exchange_rates.dart

```dart
class ExchangeRates {
  // RATE CONSTANTS
  static const double usdToUzs = 11500.0;    ← Main rate
  static const double eurToUzs = 12500.0;    (future)
  static const double rubToUzs = 120.0;      (future)
  
  // HELPER FUNCTIONS
  static double uzsToUsd(double amount) { ... }
  static double usdToUzsAmount(double amount) { ... }
  static String getExchangeRateString() { ... }
}
```

---

## 💻 How to Use It

### In Code:
```dart
import 'package:kassam/core/constants/exchange_rates.dart';

// Access rate
ExchangeRates.usdToUzs  // 11500.0

// Convert UZS to USD
ExchangeRates.uzsToUsd(5000000)  // → 434.78

// Convert USD to UZS
ExchangeRates.usdToUzsAmount(100)  // → 1150000
```

---

## ✏️ How to Change Rate

1. Open: `lib/core/constants/exchange_rates.dart`
2. Find: `static const double usdToUzs = 11500.0;`
3. Change: `static const double usdToUzs = 12000.0;` (example)
4. Save - Done! App updates everywhere automatically

---

## 📊 Current Rates in System

| Currency | Rate | Status |
|----------|------|--------|
| USD | 11,500 | ✅ Active |
| EUR | 12,500 | 📋 Ready |
| RUB | 120 | 📋 Ready |

---

## 🔗 Related Files

- Uses rate in: `lib/presentation/pages/home_page/home_page.dart`
- Can use in: Any file that imports the constant

---

## ✨ Summary

**Question:** Where is $ exchange rate defined?  
**Answer:** `lib/core/constants/exchange_rates.dart`  
**Rate:** 1 USD = 11,500 UZS  
**How to change:** Edit one line in that file  
**Status:** ✅ Centralized, organized, production-ready  
