import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final String name;
  final String type;
  final List<String> members;
  final DateTime createdAt;
  final String lastMessage;
  final int targetAmount;
  final int duration;
  final int paidCount;
  final int adminFee;
  final Map<String, dynamic> membersData;
  final List<String> winners; // Order of winners: [Winner1, Winner2, ...]

  ChatModel({
    required this.id,
    required this.name,
    required this.type,
    required this.members,
    required this.createdAt,
    required this.lastMessage,
    this.targetAmount = 0,
    this.duration = 1,
    this.paidCount = 0,
    this.adminFee = 0,
    this.membersData = const {},
    this.winners = const [],
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? 'arisan',
      members: List<String>.from(data['members'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessage: data['lastMessage'] ?? '',
      targetAmount: data['targetAmount'] ?? 0,
      duration: data['duration'] ?? 1,
      paidCount: data['paidCount'] ?? 0,
      adminFee: data['adminFee'] ?? 0,
      membersData: data['membersData'] ?? {},
      winners: List<String>.from(data['winners'] ?? []),
    );
  }
}
