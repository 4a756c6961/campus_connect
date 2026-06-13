import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_connect/utils/search_terms_builder.dart';

class UserSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> searchUsers(String input) {
    final query = normalizeSearchValue(input);

    return _firestore
        .collection('users')
        .where('searchTerms', arrayContains: query)
        .limit(20)
        .snapshots();
  }
}