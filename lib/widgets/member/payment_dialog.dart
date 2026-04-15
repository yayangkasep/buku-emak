import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/chat_model.dart';
import '../../utils/currency_formatter.dart';

class PaymentDialog {
  static void show({
    required BuildContext context,
    required String member,
    required ChatModel activity,
    required Function(int) onConfirm,
  }) {
    int perPayment = (activity.targetAmount / activity.duration).round();
    Map<String, dynamic> personalData = activity.membersData[member] ?? 
      {'paid': 0, 'remaining': activity.targetAmount};
    int remaining = personalData['remaining'] ?? activity.targetAmount;
    int installmentsLeft = perPayment > 0 ? (remaining / perPayment).ceil() : 0;

    final TextEditingController amountController = TextEditingController(text: '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Konfirmasi Pembayaran', 
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 16),
            Text('Input setoran buat:', 
              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            Text(member, 
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
            const Divider(height: 32),
            Row(
              children: [
                _miniInfo('Sisa Bayar', currencyFormatter.format(remaining), Colors.red[400]!),
                const SizedBox(width: 20),
                _miniInfo('Sisa Cicil', '$installmentsLeft Kali', Colors.orange[400]!),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: amountController,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '0',
                labelText: 'Jumlah Setoran (Rekomendasi: ${currencyFormatter.format(perPayment)})',
                labelStyle: const TextStyle(fontSize: 11),
                prefixText: 'Rp ',
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              String rawValue = amountController.text.replaceAll('.', '');
              if (rawValue.isEmpty) return;
              int finalAmount = int.tryParse(rawValue) ?? 0;
              Navigator.pop(context);
              onConfirm(finalAmount);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text('Simpan Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static Widget _miniInfo(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
