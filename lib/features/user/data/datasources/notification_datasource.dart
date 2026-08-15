import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_ruta/features/user/domain/entities/app_notification.dart';

class NotificationDatasource {
  final FirebaseFirestore _firestore;
  final _rng = Random();

  NotificationDatasource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  CollectionReference _col(String userId) =>
      _firestore.collection('notifications').doc(userId).collection('items');

  Future<void> save(AppNotification n) async {
    final data = <String, dynamic>{
      'type': n.type.name,
      'title': n.title,
      'body': n.body,
      'is_read': n.isRead,
      'created_at': n.createdAt.toIso8601String(),
    };
    if (n.discountPercent != null) {
      data['discount_percent'] = n.discountPercent;
      data['business_name'] = n.businessName;
      data['is_used'] = n.isUsed ?? false;
      data['valid_until'] = n.validUntil!.toIso8601String();
    }
    await _col(n.userId).doc(n.id).set(data);
  }

  Future<List<AppNotification>> getAll(String userId) async {
    final snap = await _col(
      userId,
    ).orderBy('created_at', descending: true).limit(100).get();
    return snap.docs.map((doc) => _fromDoc(doc, userId)).toList();
  }

  Future<int> getUnreadCount(String userId) async {
    final snap = await _col(
      userId,
    ).where('is_read', isEqualTo: false).count().get();
    return snap.count ?? 0;
  }

  Future<void> markRead(String userId, String notifId) async {
    await _col(userId).doc(notifId).update({'is_read': true});
  }

  Future<void> markAllRead(String userId) async {
    final snap = await _col(userId).where('is_read', isEqualTo: false).get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'is_read': true});
    }
    await batch.commit();
  }

  Future<void> delete(String userId, String notifId) async {
    await _col(userId).doc(notifId).delete();
  }

  Future<void> markGiftUsed(String userId, String notifId) async {
    await _col(userId).doc(notifId).update({'is_used': true});
  }

  int randomDiscount() {
    const options = [10, 15, 20, 25, 30];
    return options[_rng.nextInt(options.length)];
  }

  AppNotification _fromDoc(DocumentSnapshot doc, String userId) {
    final d = doc.data() as Map<String, dynamic>;
    final typeStr = d['type'] as String;
    final type = NotificationType.values.firstWhere((e) => e.name == typeStr);
    return AppNotification(
      id: doc.id,
      userId: userId,
      type: type,
      title: d['title'] as String,
      body: d['body'] as String,
      isRead: d['is_read'] as bool,
      createdAt: DateTime.parse(d['created_at'] as String),
      discountPercent: d['discount_percent'] as int?,
      businessName: d['business_name'] as String?,
      isUsed: d['is_used'] as bool?,
      validUntil: d['valid_until'] != null
          ? DateTime.parse(d['valid_until'] as String)
          : null,
    );
  }
}
