import 'package:flutter/material.dart';
import '../../models/chat_model.dart';
import '../../utils/currency_formatter.dart';
import '../shared/finance_stat_item.dart';

class ArisanProgressCard extends StatelessWidget {
  final ChatModel activity;
  final int totalIn;
  final int totalOut;
  final int balance;
  final int totalBailout;

  const ArisanProgressCard({
    super.key,
    required this.activity,
    required this.totalIn,
    required this.totalOut,
    required this.balance,
    required this.totalBailout,
  });

  @override
  Widget build(BuildContext context) {
    int totalPoolTarget = activity.targetAmount * activity.members.length;
    double progress = totalPoolTarget > 0 ? (totalIn / totalPoolTarget) : 0;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3), 
            blurRadius: 20, 
            offset: const Offset(0, 10)
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Uang Masuk', 
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              _buildLunasPill(),
            ],
          ),
          const SizedBox(height: 4),
          Text(currencyFormatter.format(totalIn), 
            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Progres Tabungan', 
                style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
              Text('${(progress * 100).toStringAsFixed(1)}%', 
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress > 1 ? 1 : progress,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FinanceStatItem(label: 'Saldo Kas', amount: balance, color: Colors.white),
              FinanceStatItem(label: 'Uang Keluar', amount: totalOut, color: Colors.white.withOpacity(0.8)),
              FinanceStatItem(label: 'Dana Talangan', amount: totalBailout, color: Colors.orangeAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLunasPill() {
    int fullyPaidCount = activity.membersData.values
        .where((data) => (data['percentage'] ?? 0) >= 100)
        .length;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          const Icon(Icons.people_alt, size: 12, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            '$fullyPaidCount/${activity.members.length} Lunas',
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
