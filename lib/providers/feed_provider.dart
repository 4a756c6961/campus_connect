import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_connect/services/feed_service.dart';

class FeedProvider with ChangeNotifier {
  final FeedService _feedService;

  FeedProvider(this._feedService);

  final TextEditingController controller = TextEditingController();
  bool isSending = false;

  Stream<QuerySnapshot> get postsStream => _feedService.getPostsStream();

  Future<String?> sendPost() async {
    final text = controller.text.trim();

    if (text.isEmpty) {
      return 'Bitte gib einen Text ein.';
    }

    try {
      isSending = true;
      notifyListeners();

      await _feedService.addPost(text);
      controller.clear();

      return null;
    } catch (e) {
      return 'Fehler beim Senden: $e';
    } finally {
      isSending = false;
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

  Future<void> updatePost(String postId, String newText) {
    return _feedService.updatePost(postId: postId, newText: newText);
  }

  Future<void> deletePost(String postId) {
    return _feedService.deletePost(postId);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
