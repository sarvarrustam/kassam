/// Exchange rates constants
/// Kurslari doimiy
class ExchangeRates {
  ExchangeRates._(); // Private constructor

  /// USD to UZS exchange rate
  /// 1 USD = 11,500 UZS
  static const double usdToUzs = 11500.0;

  /// Euro to UZS exchange rate (for future use)
  /// 1 EUR = ~12,500 UZS (approximate)
  static const double eurToUzs = 12500.0;

  /// RUB to UZS exchange rate (for future use)
  /// 1 RUB = ~120 UZS (approximate)
  static const double rubToUzs = 120.0;

  /// Get USD equivalent from UZS
  /// UZS miqdorni USD ga o'girish
  static double uzsToUsd(double uzsAmount) {
    return uzsAmount / usdToUzs;
  }

  /// Get UZS equivalent from USD
  /// USD miqdorni UZS ga o'girish
  static double usdToUzsAmount(double usdAmount) {
    return usdAmount * usdToUzs;
  }

  /// Get formatted exchange rate string
  /// Kurs stringini formatlash
  static String getExchangeRateString() {
    return '1 USD = $usdToUzs UZS';
  }
}
