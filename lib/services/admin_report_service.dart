import 'package:cloud_firestore/cloud_firestore.dart';

class AdminReportService {
  final FirebaseFirestore _firestore;

  AdminReportService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> getOpenReports() {
    return _firestore
        .collection('reports')
        .where('status', isEqualTo: 'open')
        .snapshots();
  }

  Future<void> markAsResolved(String reportId) async {
    await _firestore
        .collection('reports')
        .doc(reportId)
        .update({
          'status': 'resolved',
        });
  }
}