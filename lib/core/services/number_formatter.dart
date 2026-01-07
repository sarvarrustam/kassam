import 'package:flutter/services.dart';

class NumberTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Faqat raqamlarni qoldirish
    String numbersOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (numbersOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // 3 xonali guruhlash (bo'shliq bilan)
    String formatted = _formatWithSpaces(numbersOnly);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatWithSpaces(String number) {
    if (number.isEmpty) return '';

    String reversed = number.split('').reversed.join();
    String spacedReversed = '';

    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        spacedReversed += ' ';
      }
      spacedReversed += reversed[i];
    }

    return spacedReversed.split('').reversed.join();
  }
}

// Kasr raqamlar uchun formatter (nuqta bilan)
class DecimalNumberTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Raqamlar va nuqtani qoldirish
    String text = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');

    // Faqat bitta nuqta bo'lishi kerak
    int dotCount = '.'.allMatches(text).length;
    if (dotCount > 1) {
      int lastDotIndex = text.lastIndexOf('.');
      text =
          text.substring(0, lastDotIndex).replaceAll('.', '') +
          text.substring(lastDotIndex);
    }

    if (text.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Nuqta bor/yo'qligini tekshirish
    if (text.contains('.')) {
      List<String> parts = text.split('.');
      String integerPart = parts[0];
      String decimalPart = parts.length > 1 ? parts[1] : '';

      // Butun qismni formatlash (probel bilan)
      String formattedInteger = integerPart.isEmpty
          ? '0'
          : _formatWithSpaces(integerPart);

      // Kasr qismni cheklash (2 ta raqamgacha)
      if (decimalPart.length > 2) {
        decimalPart = decimalPart.substring(0, 2);
      }

      String formatted = decimalPart.isEmpty
          ? '$formattedInteger.'
          : '$formattedInteger.$decimalPart';

      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    } else {
      // Nuqta yo'q - oddiy formatlash
      String formatted = _formatWithSpaces(text);
      
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  String _formatWithSpaces(String number) {
    if (number.isEmpty) return '';

    String reversed = number.split('').reversed.join();
    String spacedReversed = '';

    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        spacedReversed += ' ';
      }
      spacedReversed += reversed[i];
    }

    return spacedReversed.split('').reversed.join();
  }
}

class NumberFormatterHelper {
  static String formatNumber(double amount) {
    if (amount == 0) return '0';

    String intString = amount.round().toString();
    return _formatWithSpaces(intString);
  }

  static double parseFormattedNumber(String formattedText) {
    // Raqamlar va nuqtani qoldirish (probel va boshqa belgilarni olib tashlash)
    String cleanedText = formattedText.replaceAll(RegExp(r'[^\d.]'), '');
    if (cleanedText.isEmpty) return 0;
    return double.tryParse(cleanedText) ?? 0;
  }

  static String _formatWithSpaces(String number) {
    if (number.isEmpty) return '';

    String reversed = number.split('').reversed.join();
    String spacedReversed = '';

    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        spacedReversed += ' ';
      }
      spacedReversed += reversed[i];
    }

    return spacedReversed.split('').reversed.join();
  }
}
