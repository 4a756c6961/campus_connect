import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ReportService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  Future<void> reportPost({
    required String postId,
    required String reportedUserId,
    required String reason,
  }) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('Du musst angemeldet sein, um einen Beitrag zu melden.');
    }

    if (currentUser.uid == reportedUserId) {
      throw Exception('Du kannst deinen eigenen Beitrag nicht melden.');
    }

    final reportId = '${currentUser.uid}_$postId';

    final reportRef = _firestore.collection('reports').doc(reportId);

    final existingReport = await reportRef.get();

    if (existingReport.exists) {
      throw ReportAlreadyExistsException();
    }

    await reportRef.set({
      'postId': postId,
      'reportedUserId': reportedUserId,
      'reporterUserId': currentUser.uid,
      'reason': reason,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

class ReportAlreadyExistsException implements Exception {}
