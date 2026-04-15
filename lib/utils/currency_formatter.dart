import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

final currencyFormatter = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) return newValue;
    final formatter = NumberFormat('#,###', 'id_ID');
    String baseText = newValue.text.replaceAll('.', '');
    if (baseText.isEmpty) return newValue.copyWith(text: '');
    int value = int.parse(baseText);
    String newText = formatter.format(value);
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
