import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import 'package:intl/intl.dart';

class ChatTile extends StatelessWidget {
  final ChatModel chat;
  final VoidCallback onTap;

  const ChatTile({super.key, required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (chat.type) {
      case 'tabungan':
        icon = Icons.account_balance_wallet;
        color = Colors.blue;
        break;
      case 'tagihan':
        icon = Icons.receipt_long;
        color = Colors.orange;
        break;
      case 'paket':
        icon = Icons.inventory_2;
        color = Colors.purple;
        break;
      default:
        icon = Icons.people;
        color = const Color(0xFF10B981);
    }

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 28),
      ),
      title: Text(
        chat.name,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Row(
        children: [
          Text(
            chat.type.toUpperCase(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5),
          ),
          const SizedBox(width: 8),
          Text(
            NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(chat.targetAmount),
            style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            DateFormat('HH:mm').format(chat.createdAt),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (chat.members.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                chat.type == 'arisan' 
                  ? '${chat.winners.length}/${chat.members.length}' 
                  : '${chat.paidCount}/${chat.members.length}',
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
