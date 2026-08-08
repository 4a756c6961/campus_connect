import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AdminService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  Future<bool> isCurrentUserAdmin() async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return false;
    }

    final doc =
        await _firestore
            .collection('admin')
            .doc(currentUser.uid)
            .get();

    if (!doc.exists) {
      return false;
    }

    final data = doc.data();

    return data?['active'] == true;
  }
}