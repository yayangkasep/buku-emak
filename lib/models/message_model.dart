import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String chatId;
  final String type; // payment, bailout, info, winner
  final String user;
  final String text;
  final DateTime createdAt;
  final int amount;
  final String status;
  
  // Metadata for global history
  final String? activityName;
  final String? activityType;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.type,
    required this.user,
    required this.text,
    required this.createdAt,
    this.amount = 0,
    this.status = '',
    this.activityName,
    this.activityType,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      type: data['type'] ?? 'text',
      user: data['user'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      amount: data['amount'] ?? 0,
      status: data['status'] ?? '',
      activityName: data['activityName'],
      activityType: data['activityType'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'type': type,
      'user': user,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'amount': amount,
      'status': status,
      'activityName': activityName,
      'activityType': activityType,
    };
  }
}
