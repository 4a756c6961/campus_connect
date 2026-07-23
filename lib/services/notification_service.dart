import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _firestore;

  NotificationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _notificationsCollection(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getNotifications(String userId) {
    return _notificationsCollection(
      userId,
    ).orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> createNotification({
    required String receiverId,
    required String senderId,
    required String senderName,
    required String type,
    required String message,
    String? senderPhotoUrl,
    String? postId,
  }) async {
    // Keine Benachrichtigung erzeugen, wenn jemand mit dem
    // eigenen Beitrag interagiert.
    if (receiverId == senderId) {
      return;
    }

    await _notificationsCollection(receiverId).add({
      'type': type,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'postId': postId,
      'message': message,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAsRead({
    required String userId,
    required String notificationId,
  }) async {
    await _notificationsCollection(
      userId,
    ).doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllAsRead(String userId) async {
    final snapshot =
        await _notificationsCollection(
          userId,
        ).where('isRead', isEqualTo: false).get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();

    for (final document in snapshot.docs) {
      batch.update(document.reference, {'isRead': true});
    }

    await batch.commit();
  }

  Future<void> deleteNotification({
    required String userId,
    required String notificationId,
  }) async {
    await _notificationsCollection(userId).doc(notificationId).delete();
  }
}
