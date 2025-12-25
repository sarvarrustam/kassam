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

class NumberFormatterHelper {
  static String formatNumber(double amount) {
    if (amount == 0) return '0';
    
    String intString = amount.round().toString();
    return _formatWithSpaces(intString);
  }
  
  static double parseFormattedNumber(String formattedText) {
    String numbersOnly = formattedText.replaceAll(RegExp(r'[^\d]'), '');
    if (numbersOnly.isEmpty) return 0;
    return double.parse(numbersOnly);
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