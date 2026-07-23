import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campus_connect/models/selected_gif.dart';
import 'package:campus_connect/services/notification_service.dart';

class FeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

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

  Future<void> addPost(
    String text, {
    SelectedGif? gif,
    List<String> tags = const [],
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kein eingeloggter Benutzer gefunden.');
    }

    final trimmed = text.trim();

    if (trimmed.isEmpty && gif == null) {
      throw Exception('Der Beitrag darf nicht leer sein.');
    }

    final displayName = await _getDisplayName(user);
    final photoUrl = await _getPhotoUrl(user);

    await _firestore.collection('posts').add({
      'text': trimmed,
      'userId': user.uid,
      'userEmail': user.email,
      'userName': displayName,
      'photoUrl': photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'editedAt': null,
      'gif': gif?.toMap(),
      'tags': tags,
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

    final displayName = await _getDisplayName(user);
    final photoUrl = await _getPhotoUrl(user);

    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .add({
          'text': trimmed,
          'userId': user.uid,
          'userEmail': user.email,
          'authorName': displayName,
          'photoUrl': photoUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<bool> toggleLike(String postId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Kein eingeloggter Benutzer gefunden.');
    }

    final postRef = _firestore.collection('posts').doc(postId);

    final likeRef = postRef.collection('likes').doc(user.uid);

    final likeDoc = await likeRef.get();

    if (likeDoc.exists) {
      await likeRef.delete();

      // false bedeutet: Der vorhandene Like wurde entfernt.
      return false;
    }

    await likeRef.set({
      'userId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final postSnapshot = await postRef.get();
    final postData = postSnapshot.data();

    if (postData == null) {
      return true;
    }

    final postOwnerId = (postData['userId'] ?? '').toString();

    if (postOwnerId.isEmpty || postOwnerId == user.uid) {
      return true;
    }

    final senderName = await _getDisplayName(user);
    final senderPhotoUrl = await _getPhotoUrl(user);

    await _notificationService.createNotification(
      receiverId: postOwnerId,
      senderId: user.uid,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      type: 'like',
      message: '$senderName gefällt dein Beitrag.',
      postId: postId,
    );

    // true bedeutet: Ein neuer Like wurde gesetzt.
    return true;
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

  Future<String> _getDisplayName(User user) async {
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();

    final firestoreDisplayName =
        (userData?['displayName'] ??
                userData?['userName'] ??
                userData?['username'] ??
                userData?['name'] ??
                '')
            .toString()
            .trim();

    if (firestoreDisplayName.isNotEmpty) {
      return firestoreDisplayName;
    }

    final authDisplayName = (user.displayName ?? '').trim();

    if (authDisplayName.isNotEmpty) {
      return authDisplayName;
    }

    final email = (user.email ?? '').trim();

    if (email.isNotEmpty) {
      return email;
    }

    return 'Unbekannt';
  }

  Future<String> _getPhotoUrl(User user) async {
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();

    final firestorePhotoUrl =
        (userData?['photoUrl'] ??
                userData?['profileImageUrl'] ??
                userData?['imageUrl'] ??
                userData?['avatarUrl'] ??
                '')
            .toString()
            .trim();

    if (firestorePhotoUrl.isNotEmpty) {
      return firestorePhotoUrl;
    }

    return user.photoURL ?? '';
  }

  Future<void> updateComment({
    required String postId,
    required String commentId,
    required String text,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Kein eingeloggter Benutzer gefunden.');
    }

    final trimmedText = text.trim();

    if (trimmedText.isEmpty) {
      throw Exception('Der Kommentar darf nicht leer sein.');
    }

    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .update({
          'text': trimmedText,
          'editedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Kein eingeloggter Benutzer gefunden.');
    }

    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }
}
