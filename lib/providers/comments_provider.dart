import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:campus_connect/services/feed_service.dart';

class CommentsProvider extends ChangeNotifier {
  final FeedService _feedService;
  final String postId;

  CommentsProvider(this._feedService, this.postId);

  final TextEditingController controller = TextEditingController();

  bool _isSending = false;
  bool get isSending => _isSending;

  Stream<QuerySnapshot> get commentsStream =>
      _feedService.getCommentsStream(postId);

  Future<String?> sendComment() async {
    final text = controller.text.trim();

    if (text.isEmpty) {
      return 'Bitte gib einen Kommentar ein.';
    }

    _isSending = true;
    notifyListeners();

    try {
      await _feedService.addComment(postId: postId, text: text);
      controller.clear();
      return null;
    } catch (e) {
      return 'Kommentar konnte nicht gesendet werden: $e';
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
