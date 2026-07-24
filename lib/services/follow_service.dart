import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FollowService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _followerReference({
    required String userId,
    required String followerId,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('followers')
        .doc(followerId);
  }

  DocumentReference<Map<String, dynamic>> _followingReference({
    required String userId,
    required String followedUserId,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .doc(followedUserId);
  }

  Stream<bool> isFollowingStream(String followedUserId) {
    final currentUserId = this.currentUserId;

    if (currentUserId == null || currentUserId == followedUserId) {
      return Stream.value(false);
    }

    return _followingReference(
      userId: currentUserId,
      followedUserId: followedUserId,
    ).snapshots().map((snapshot) => snapshot.exists);
  }

  Stream<int> followersCountStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('followers')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> followingCountStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> followUser(String followedUserId) async {
    final currentUserId = this.currentUserId;

    if (currentUserId == null) {
      throw StateError('Es ist kein Nutzer angemeldet.');
    }

    if (currentUserId == followedUserId) {
      throw StateError('Du kannst dir nicht selbst folgen.');
    }

    final batch = _firestore.batch();

    final followerReference = _followerReference(
      userId: followedUserId,
      followerId: currentUserId,
    );

    final followingReference = _followingReference(
      userId: currentUserId,
      followedUserId: followedUserId,
    );

    final data = {
      'createdAt': FieldValue.serverTimestamp(),
    };

    batch.set(followerReference, data);
    batch.set(followingReference, data);

    await batch.commit();
  }

  Future<void> unfollowUser(String followedUserId) async {
    final currentUserId = this.currentUserId;

    if (currentUserId == null) {
      throw StateError('Es ist kein Nutzer angemeldet.');
    }

    if (currentUserId == followedUserId) {
      return;
    }

    final batch = _firestore.batch();

    final followerReference = _followerReference(
      userId: followedUserId,
      followerId: currentUserId,
    );

    final followingReference = _followingReference(
      userId: currentUserId,
      followedUserId: followedUserId,
    );

    batch.delete(followerReference);
    batch.delete(followingReference);

    await batch.commit();
  }
}