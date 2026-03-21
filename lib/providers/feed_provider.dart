import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:campus_connect/services/feed_service.dart';

class FeedProvider extends ChangeNotifier {
  final FeedService _feedService;

  FeedProvider(this._feedService);

  final TextEditingController controller = TextEditingController();

  bool _isSending = false;
  bool get isSending => _isSending;

  Stream<QuerySnapshot> get postsStream => _feedService.getPostsStream();

  Future<String?> sendPost() async {
    final text = controller.text.trim();

    if (text.isEmpty) {
      return 'Bitte gib einen Text ein.';
    }

    _isSending = true;
    notifyListeners();

    try {
      await _feedService.addPost(text);
      controller.clear();
      return null;
    } catch (e) {
      return 'Fehler beim Posten: $e';
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<String?> toggleLike(String postId) async {
    try {
      await _feedService.toggleLike(postId);
      return null;
    } catch (e) {
      return 'Fehler beim Liken: $e';
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
