import 'package:flutter/material.dart';
import '../../models/chat_model.dart';
import '../../utils/currency_formatter.dart';
import 'package:intl/intl.dart';

class ArisanShakeSection extends StatelessWidget {
  final ChatModel activity;
  final int balance;
  final Function(int bailoutAmount) onShakeRequested;

  const ArisanShakeSection({
    super.key,
    required this.activity,
    required this.balance,
    required this.onShakeRequested,
  });

  @override
  Widget build(BuildContext context) {
    bool isAllWon = activity.winners.length >= activity.members.length;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton.icon(
          onPressed: isAllWon ? null : () => _confirmShake(context),
          icon: const Icon(Icons.casino_outlined),
          label: Text(
            isAllWon ? 'Semua Sudah Menang' : 'Kocok Arisan Sekarang!', 
            style: const TextStyle(fontWeight: FontWeight.bold)
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E293B),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
          ),
        ),
      ),
    );
  }

  void _confirmShake(BuildContext context) {
    bool isInsufficient = balance < activity.targetAmount;
    final bailoutController = TextEditingController(
      text: isInsufficient ? NumberFormat('#,###', 'id_ID').format(activity.targetAmount - balance) : ''
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(
              isInsufficient ? Icons.report_problem_rounded : Icons.casino_outlined, 
              color: isInsufficient ? Colors.red : const Color(0xFF10B981)
            ),
            const SizedBox(width: 10),
            Text(isInsufficient ? 'Saldo Kurang!' : 'Kocok Arisan?', 
              style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isInsufficient) ...[
              const Text('Waduh, uang di kas nggak cukup buat bayar pemenang selanjutnya.', 
                style: TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              Text('Kurang: ${currencyFormatter.format(activity.targetAmount - balance)}', 
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Masukkan Jumlah Dana Talangan:', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                controller: bailoutController,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
            ] else 
              const Text('Siapkan gelas keberuntungan! Kocokan akan memilih satu pemenang dari yang belum dapat.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              int bailoutAmt = 0;
              if (isInsufficient) {
                bailoutAmt = int.tryParse(bailoutController.text.replaceAll('.', '').replaceAll('Rp ', '')) ?? 0;
              }
              Navigator.pop(context);
              onShakeRequested(bailoutAmt);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isInsufficient ? Colors.orange : const Color(0xFF10B981), 
              foregroundColor: Colors.white
            ),
            child: Text(isInsufficient ? 'Ya, Pake Dana Talangan' : 'Mulai Kocok!'),
          ),
        ],
      ),
    );
  }
}
