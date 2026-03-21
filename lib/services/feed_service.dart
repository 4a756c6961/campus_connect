import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> getPostsStream() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getCommentsStream(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot> getLikesStream(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .snapshots();
  }

  Future<void> addPost(String text) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kein eingeloggter Benutzer gefunden.');
    }

    await _firestore.collection('posts').add({
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'userId': user.uid,
      'userEmail': user.email ?? '',
      'userName': user.displayName ?? '',
    });
  }

  Future<void> addComment({
    required String postId,
    required String text,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kein eingeloggter Benutzer gefunden.');
    }

    final displayName = await _getDisplayName(user);

    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .add({
          'text': text,
          'userId': user.uid,
          'authorId': user.uid,
          'authorName': displayName,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> toggleLike(String postId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kein eingeloggter Benutzer gefunden.');
    }

    final likeRef = _firestore
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(user.uid);

    final likeDoc = await likeRef.get();

    if (likeDoc.exists) {
      await likeRef.delete();
    } else {
      await likeRef.set({
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<String> _getDisplayName(User user) async {
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();

    final username = userData?['username']?.toString().trim();

    if (username != null && username.isNotEmpty) {
      return username;
    }

    return user.email ?? 'Unbekannt';
  }
}
