import 'package:flutter/material.dart';
import '../../utils/currency_formatter.dart';

class FinanceStatItem extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;

  const FinanceStatItem({
    super.key,
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          currencyFormatter.format(amount < 0 ? amount.abs() : amount),
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
