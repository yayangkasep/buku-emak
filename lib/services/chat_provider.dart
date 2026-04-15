import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import 'firebase_service.dart';

class ChatProvider with ChangeNotifier {
  final FirebaseService _service = FirebaseService();
  List<ChatModel> _chats = [];
  bool _isLoading = false;

  List<ChatModel> get chats => _chats;
  bool get isLoading => _isLoading;

  void fetchChats() {
    _isLoading = true;
    _service.getChats().listen((data) {
      _chats = data;
      _isLoading = false;
      notifyListeners();
    });
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _service.getMessages(chatId);
  }

  Future<void> sendMessage(String chatId, MessageModel message) async {
    await _service.sendMessage(chatId, message);
  }

  // Feature: Create new Arisan/Tabungan/Tagihan
  Future<void> createGroup({
    required String name,
    required String type,
    required List<String> members,
    int? totalPool,
  }) async {
    await FirebaseFirestore.instance.collection('chats').add({
      'name': name,
      'type': type,
      'members': members,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': 'Grup dibuat',
      'totalPool': totalPool ?? 0,
      'paidCount': 0,
    });
  }
}
