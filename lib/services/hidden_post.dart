import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HiddenPostService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  HiddenPostService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _hiddenPostsCollection(
    String userId,
  ) {
    return _firestore.collection('users').doc(userId).collection('hiddenPosts');
  }

  Future<void> hidePost(String postId) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw StateError(
        'Zum Verbergen eines Beitrags ist eine Anmeldung nötig.',
      );
    }

    await _hiddenPostsCollection(currentUser.uid).doc(postId).set({
      'postId': postId,
      'hiddenAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unhidePost(String postId) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw StateError(
        'Zum Wiederherstellen eines Beitrags ist eine Anmeldung nötig.',
      );
    }

    await _hiddenPostsCollection(currentUser.uid).doc(postId).delete();
  }

  Stream<Set<String>> hiddenPostIdsStream() {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Stream.value(<String>{});
    }

    return _hiddenPostsCollection(
      currentUser.uid,
    ).snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }
}
