import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/message_model.dart';
import '../../utils/currency_formatter.dart';
import 'package:intl/intl.dart';

class HistoryTile extends StatelessWidget {
  final MessageModel message;
  final VoidCallback? onTap;

  const HistoryTile({super.key, required this.message, this.onTap});

  Future<String> _getActivityName() async {
    // If we already have the name, just return it
    if (message.activityName != null && message.activityName != 'Kegiatan Umum') {
      return message.activityName!;
    }

    // Otherwise, we need to fetch the parent chat document
    try {
      String? foundType = message.activityType;
      DocumentSnapshot? chatDoc;

      if (foundType != null) {
        chatDoc = await FirebaseFirestore.instance.collection(foundType).doc(message.chatId).get();
      } else {
        // Search across all possible types for legacy data
        final types = ['arisan', 'tabungan', 'tagihan', 'paket'];
        for (var t in types) {
          var doc = await FirebaseFirestore.instance.collection(t).doc(message.chatId).get();
          if (doc.exists) {
            chatDoc = doc;
            break;
          }
        }
      }

      if (chatDoc != null && chatDoc.exists) {
        return chatDoc.get('name') ?? 'Kegiatan Umum';
      }
    } catch (e) {
      debugPrint('Error fetching activity name: $e');
    }

    return 'Kegiatan Umum';
  }

  @override
  Widget build(BuildContext context) {
    bool isOut = message.amount < 0;
    Color categoryColor = _getCategoryColor(message.activityType ?? 'arisan');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildLeadingIcon(isOut),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              (message.activityType ?? 'Arisan').toUpperCase(),
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: categoryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FutureBuilder<String>(
                              future: _getActivityName(),
                              initialData: message.activityName ?? 'Loading...',
                              builder: (context, snapshot) {
                                return Text(
                                  snapshot.data ?? 'Kegiatan Umum',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message.user,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      Text(
                        message.text,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormatter.format(message.amount),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: isOut ? Colors.redAccent : Colors.green[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM, HH:mm').format(message.createdAt),
                      style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(bool isOut) {
    IconData icon;
    Color color;

    if (message.type == 'bailout') {
      icon = Icons.account_balance_rounded;
      color = Colors.orange;
    } else if (isOut) {
      icon = Icons.arrow_outward_rounded;
      color = Colors.redAccent;
    } else {
      icon = Icons.add_chart_rounded;
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Color _getCategoryColor(String type) {
    switch (type.toLowerCase()) {
      case 'tabungan': return Colors.blue;
      case 'tagihan': return Colors.orange;
      case 'paket': return Colors.purple;
      default: return const Color(0xFF10B981);
    }
  }
}
