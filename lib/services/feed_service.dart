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

    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw Exception('Der Beitrag darf nicht leer sein.');
    }

    await _firestore.collection('posts').add({
      'text': trimmed,
      'userId': user.uid,
      'userEmail': user.email,
      'createdAt': FieldValue.serverTimestamp(),
      'editedAt': null,
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

    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw Exception('Der Kommentar darf nicht leer sein.');
    }

    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .add({
          'text': trimmed,
          'userId': user.uid,
          'userEmail': user.email,
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

  Future<void> updatePost({
    required String postId,
    required String newText,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kein eingeloggter Benutzer gefunden.');
    }

    final trimmed = newText.trim();
    if (trimmed.isEmpty) {
      throw Exception('Der Beitrag darf nicht leer sein.');
    }

    final postRef = _firestore.collection('posts').doc(postId);
    final postSnap = await postRef.get();

    if (!postSnap.exists) {
      throw Exception('Beitrag wurde nicht gefunden.');
    }

    final data = postSnap.data();
    if (data == null || data['userId'] != user.uid) {
      throw Exception('Du darfst nur deine eigenen Beiträge bearbeiten.');
    }

    await postRef.update({
      'text': trimmed,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePost(String postId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kein eingeloggter Benutzer gefunden.');
    }

    final postRef = _firestore.collection('posts').doc(postId);
    final postSnap = await postRef.get();

    if (!postSnap.exists) {
      throw Exception('Beitrag wurde nicht gefunden.');
    }

    final data = postSnap.data();
    if (data == null || data['userId'] != user.uid) {
      throw Exception('Du darfst nur deine eigenen Beiträge löschen.');
    }

    final commentsSnap = await postRef.collection('comments').get();
    final likesSnap = await postRef.collection('likes').get();

    final batch = _firestore.batch();

    for (final doc in commentsSnap.docs) {
      batch.delete(doc.reference);
    }

    for (final doc in likesSnap.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(postRef);

    await batch.commit();
  }
}
