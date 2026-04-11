import 'package:flutter/services.dart';

/// TextInputFormatter для автоформатирования российских номеров телефонов.
/// Формат: +7 (XXX) XXX-XX-XXX
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Получаем только цифры из нового значения
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Ограничиваем 11 цифрами (7 + 10 цифр номера)
    if (digits.length > 11) {
      digits = digits.substring(0, 11);
    }

    // Если начинается с 8, заменяем на 7
    if (digits.isNotEmpty && digits.startsWith('8')) {
      digits = '7' + digits.substring(1);
    }

    // Если первая цифра не 7, добавляем 7
    if (digits.isNotEmpty && !digits.startsWith('7')) {
      digits = '7' + digits;
    }

    // Форматируем
    String formatted;
    if (digits.isEmpty) {
      formatted = '';
    } else if (digits.length <= 1) {
      formatted = '+$digits';
    } else if (digits.length <= 4) {
      formatted = '+7 (${digits.substring(1)}';
    } else if (digits.length <= 7) {
      formatted = '+7 (${digits.substring(1, 4)}) ${digits.substring(4)}';
    } else if (digits.length <= 9) {
      formatted = '+7 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7)}';
    } else {
      formatted = '+7 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7, 9)}-${digits.substring(9)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Извлекает только цифры из отформатированного номера
  static String extractDigits(String formatted) {
    return formatted.replaceAll(RegExp(r'[^0-9]'), '');
  }
}
