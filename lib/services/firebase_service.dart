import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Create new activity (Arisan/Tabungan/Paket)
  Future<void> createActivity(Map<String, dynamic> data) async {
    String type = data['type'] ?? 'arisan';
    String customId = _uuid.v4(); // Force use UUID
    
    // Initialize members data summary
    Map<String, dynamic> membersData = {};
    List<String> members = List<String>.from(data['members'] ?? []);
    int target = data['targetAmount'] ?? 0;

    for (var member in members) {
      membersData[member] = {
        'paid': 0,
        'remaining': target,
        'percentage': 0,
      };
    }

    data['id'] = customId;
    data['membersData'] = membersData;

    await _db.collection(type).doc(customId).set(data);
  }

  // Get real-time counts for each category to show on Dashboard
  Stream<Map<String, int>> getCategoryCounts() {
    return Rx.combineLatest4<QuerySnapshot, QuerySnapshot, QuerySnapshot, QuerySnapshot, Map<String, int>>(
      _db.collection('arisan').snapshots(),
      _db.collection('tabungan').snapshots(),
      _db.collection('tagihan').snapshots(),
      _db.collection('paket').snapshots(),
      (arisan, tabungan, tagihan, paket) => {
        'arisan': arisan.docs.length,
        'tabungan': tabungan.docs.length,
        'tagihan': tagihan.docs.length,
        'paket': paket.docs.length,
      },
    );
  }

  // Get only activities of a specific type (filtered)
  Stream<List<ChatModel>> getActivitiesByType(String type) {
    return _db.collection(type)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatModel.fromFirestore(doc))
            .toList());
  }

  // Get stream for specific type
  Stream<List<ChatModel>> getActivities(String type) {
    return _db.collection(type).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ChatModel.fromFirestore(doc)).toList();
    });
  }

  // Get all activities (Combine Arisan, Tabungan, Tagihan, Paket)
  Stream<List<ChatModel>> getAllActivities() {
    return Rx.combineLatest4<QuerySnapshot, QuerySnapshot, QuerySnapshot, QuerySnapshot, List<ChatModel>>(
      _db.collection('arisan').snapshots(),
      _db.collection('tabungan').snapshots(),
      _db.collection('tagihan').snapshots(),
      _db.collection('paket').snapshots(),
      (arisan, tabungan, tagihan, paket) {
        final allDocs = [
          ...arisan.docs,
          ...tabungan.docs,
          ...tagihan.docs,
          ...paket.docs,
        ];
        return allDocs.map((doc) => ChatModel.fromFirestore(doc)).toList();
      },
    );
  }

  // Get real-time global history using Collection Group with optional filters
  Stream<List<MessageModel>> getGlobalHistory({
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _db.collectionGroup('messages');

    // Filter by category if specified
    if (category != null && category != 'Semua') {
      query = query.where('activityType', isEqualTo: category.toLowerCase());
    }

    // Filter by date range if specified
    if (startDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList());
  }

  // Send payment and update summary
  Future<void> recordPayment(String type, String activityId, MessageModel message) async {
    // 1. Fetch group metadata first
    DocumentSnapshot activityDoc = await _db.collection(type).doc(activityId).get();
    String activityName = (activityDoc.data() as Map<String, dynamic>?)?['name'] ?? 'Unknown';

    // 2. Save to subcollection history with metadata
    await _db.collection(type).doc(activityId).collection('messages').add({
      ...message.toFirestore(),
      'activityName': activityName,
      'activityType': type,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3. Update the parent document's member data summary
    DocumentReference docRef = _db.collection(type).doc(activityId);
    
    await _db.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      Map<String, dynamic> membersData = Map<String, dynamic>.from(data['membersData'] ?? {});
      
      if (membersData.containsKey(message.user)) {
        int currentPaid = membersData[message.user]['paid'] ?? 0;
        int newPaid = currentPaid + message.amount;
        int target = data['targetAmount'] ?? 0;
        double newPercentage = target > 0 ? (newPaid / target) * 100 : 0;

        membersData[message.user] = {
          'paid': newPaid,
          'remaining': target - newPaid,
          'percentage': newPercentage.round(),
        };

        transaction.update(docRef, {
          'membersData': membersData,
          'paidCount': FieldValue.increment(1),
          'lastMessage': '${message.user} baru saja bayar Rp ${message.amount}',
        });
      }
    });
  }

  // Shake the Arisan to pick a winner with optional bailout tracking
  Future<String?> shakeArisan(String activityId, {int bailoutAmount = 0}) async {
    DocumentReference docRef = _db.collection('arisan').doc(activityId);
    
    return await _db.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return null;

      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      String activityName = data['name'] ?? 'Unknown';
      List<String> members = List<String>.from(data['members'] ?? []);
      List<String> winners = List<String>.from(data['winners'] ?? []);
      
      List<String> remaining = members.where((m) => !winners.contains(m)).toList();
      if (remaining.isEmpty) return "ALL_WON";

      String winner = (remaining..shuffle()).first;
      winners.add(winner);

      transaction.update(docRef, {
        'winners': winners,
        'lastMessage': '🏆 PEMENANG: $winner!',
      });

      // 1. Record the Bailout if any (Dana Galang)
      if (bailoutAmount > 0) {
        await docRef.collection('messages').add({
          'chatId': activityId,
          'type': 'bailout', 
          'user': 'Emak (Talangan)',
          'text': 'Dana Talangan masuk untuk menutupi kekurangan kas.',
          'amount': bailoutAmount, 
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'debt',
          'activityName': activityName,
          'activityType': 'arisan',
        });
      }

      // 2. Record the Payout
      int payoutAmount = data['targetAmount'] ?? 0;
      await docRef.collection('messages').add({
        'chatId': activityId,
        'type': 'winner', 
        'user': 'Sistem',
        'text': '$winner memenangkan Arisan!',
        'amount': -payoutAmount,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'won',
        'activityName': activityName,
        'activityType': 'arisan',
      });

      return winner;
    });
  }

  Stream<List<MessageModel>> getMessages(String type, String activityId) {
    return _db
        .collection(type)
        .doc(activityId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList();
    });
  }
}
