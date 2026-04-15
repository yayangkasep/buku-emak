import 'package:flutter/material.dart';
import '../../models/chat_model.dart';
import '../../utils/currency_formatter.dart';
import 'payment_dialog.dart';

class MemberListSection extends StatelessWidget {
  final ChatModel activity;
  final Function(String, int) onPaymentRecorded;

  const MemberListSection({
    super.key,
    required this.activity,
    required this.onPaymentRecorded,
  });

  @override
  Widget build(BuildContext context) {
    List<String> sortedMembers = List<String>.from(activity.members);
    sortedMembers.sort((a, b) {
      int pctA = activity.membersData[a]?['percentage'] ?? 0;
      int pctB = activity.membersData[b]?['percentage'] ?? 0;
      return pctB.compareTo(pctA);
    });

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daftar Anggota', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...sortedMembers.map((member) => _buildMemberItem(context, member)),
        ],
      ),
    );
  }

  Widget _buildMemberItem(BuildContext context, String member) {
    Map<String, dynamic> personalData = activity.membersData[member] ?? 
      {'paid': 0, 'percentage': 0, 'remaining': activity.targetAmount};
    bool isFullyPaid = (personalData['percentage'] ?? 0) >= 100;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
           Expanded(
            child: InkWell(
              onTap: () => _showMemberDetail(context, member, personalData),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: isFullyPaid ? const Color(0xFF10B981).withOpacity(0.1) : Colors.grey[100],
                      child: Icon(
                        isFullyPaid ? Icons.check : Icons.person_outline, 
                        size: 18, 
                        color: isFullyPaid ? const Color(0xFF10B981) : Colors.grey
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(member, 
                          style: TextStyle(
                            fontWeight: isFullyPaid ? FontWeight.bold : FontWeight.w600, 
                            fontSize: 15, 
                            color: isFullyPaid ? Colors.black : Colors.grey[800]
                          )
                        ),
                        Text('${personalData['percentage']}% • Klik Detail >', 
                          style: TextStyle(
                            fontSize: 10, 
                            color: isFullyPaid ? const Color(0xFF10B981) : Colors.blue[600], 
                            fontWeight: FontWeight.bold
                          )
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!isFullyPaid)
            ElevatedButton(
              onPressed: () => PaymentDialog.show(
                context: context,
                member: member,
                activity: activity,
                onConfirm: (amount) => onPaymentRecorded(member, amount),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                foregroundColor: const Color(0xFF10B981),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Bayar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            )
          else
            const Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('LUNAS', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w900, fontSize: 11)),
                Icon(Icons.verified, color: Color(0xFF10B981), size: 14),
              ],
            ),
        ],
      ),
    );
  }

  void _showMemberDetail(BuildContext context, String member, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rapor Pembayaran', style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(member, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.star_rounded, color: Color(0xFF10B981)),
                )
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                _statItem('Sudah Bayar', currencyFormatter.format(data['paid'] ?? 0), Colors.green),
                const SizedBox(width: 24),
                _statItem('Sisa Tagihan', currencyFormatter.format(data['remaining'] ?? 0), Colors.red),
                const SizedBox(width: 24),
                _statItem('Persen', '${data['percentage'] ?? 0}%', Colors.blue),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Status Anggota:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Text((data['percentage'] ?? 0) >= 100 
              ? '✅ Ibu ini jagoan! Sudah lunas.' 
              : '⏳ Masih ada sisa tagihan, semangat bayarnya ya!', 
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
