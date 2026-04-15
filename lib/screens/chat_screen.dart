import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/firebase_service.dart';
import '../utils/currency_formatter.dart';

// Import Modular Widgets
import '../widgets/arisan/arisan_progress_card.dart';
import '../widgets/arisan/arisan_shake_section.dart';
import '../widgets/arisan/arisan_winners_card.dart';
import '../widgets/member/member_list_section.dart';

class ChatScreen extends StatefulWidget {
  final ChatModel chat;
  const ChatScreen({super.key, required this.chat});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection(widget.chat.type)
          .doc(widget.chat.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final activityData = ChatModel.fromFirestore(snapshot.data!);

        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          appBar: AppBar(
            title: Text(activityData.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          body: StreamBuilder<List<MessageModel>>(
            stream: _firebaseService.getMessages(activityData.type, activityData.id),
            builder: (context, msgSnapshot) {
              final payments = msgSnapshot.data ?? [];

              // Calculate financial state
              int totalIn = payments
                  .where((p) => p.amount > 0 && p.type != 'bailout')
                  .fold(0, (sum, item) => sum + item.amount);
              int totalOut = payments
                  .where((p) => p.amount < 0)
                  .fold(0, (sum, item) => sum + item.amount.abs());
              int totalBailout = payments
                  .where((p) => p.type == 'bailout')
                  .fold(0, (sum, item) => sum + item.amount);
              int balance = (totalIn + totalBailout) - totalOut;

              return SingleChildScrollView(
                child: Column(
                  children: [
                    // ARISAN FEATURE
                    if (activityData.type == 'arisan') ...[
                      ArisanProgressCard(
                        activity: activityData,
                        totalIn: totalIn,
                        totalOut: totalOut,
                        balance: balance,
                        totalBailout: totalBailout,
                      ),
                      ArisanShakeSection(
                        activity: activityData,
                        balance: balance,
                        onShakeRequested: (bailout) => _performShake(activityData, bailout),
                      ),
                      ArisanWinnersCard(activity: activityData),
                    ],

                    // TABUNGAN FEATURE (Future proofing)
                    if (activityData.type == 'tabungan') ...[
                      // We can create TabunganProgressCard later here
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text("Tabungan Dashboard Coming Soon"),
                      ),
                    ],

                    // SHARED MEMBER MANAGEMENT
                    MemberListSection(
                      activity: activityData,
                      onPaymentRecorded: (member, amount) => _executePayment(activityData, member, amount),
                    ),

                    // GLOBAL TRANSACTION HISTORY
                    _buildHistoryList(payments),
                    const SizedBox(height: 100), // Padding bottom
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _performShake(ChatModel activity, int bailoutAmount) async {
    if (bailoutAmount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('⚠️ Menggunakan Dana Talangan: ${currencyFormatter.format(bailoutAmount)}'),
        backgroundColor: Colors.orange,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🍀 Menggoncang gelas kocokan...')));
    }

    String? winner = await _firebaseService.shakeArisan(activity.id, bailoutAmount: bailoutAmount);

    if (winner != null && winner != "ALL_WON") {
      _showWinnerDialog(winner, activity.winners.length + 1);
    }
  }

  void _showWinnerDialog(String winner, int turn) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_rounded, color: Colors.orange, size: 80),
            const SizedBox(height: 16),
            const Text('🏆 SELAMAT! 🏆', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            Text(winner, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
            const SizedBox(height: 8),
            Text('Adalah pemenang kocokan ke-$turn', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: const Text('ALHAMDULILLAH', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _executePayment(ChatModel activity, String member, int amount) async {
    final message = MessageModel(
      id: '',
      chatId: activity.id,
      type: 'payment',
      user: member,
      amount: amount,
      status: 'paid',
      text: '$member telah membayar iuran',
      createdAt: DateTime.now(),
    );

    await _firebaseService.recordPayment(activity.type, activity.id, message);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Selesai! Pembayaran $member tersimpan.'),
            backgroundColor: const Color(0xFF10B981)),
      );
    }
  }

  Widget _buildHistoryList(List<MessageModel> payments) {
    if (payments.isEmpty) return const SizedBox();
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Log Transaksi Global', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          ...payments.map((p) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  p.amount < 0 ? Icons.outbox : Icons.receipt_long,
                  color: p.amount < 0 ? Colors.red : Colors.blue,
                ),
                title: Text(p.user, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(DateFormat('dd MMM, HH:mm').format(p.createdAt), style: const TextStyle(fontSize: 11)),
                trailing: Text(
                  currencyFormatter.format(p.amount),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: p.amount < 0 ? Colors.red : Colors.green),
                ),
              )),
        ],
      ),
    );
  }
}
