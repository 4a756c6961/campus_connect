import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_connect/services/feed_service.dart';
import 'package:campus_connect/models/selected_gif.dart';

class FeedProvider with ChangeNotifier {
  final FeedService _feedService;

  FeedProvider(this._feedService);

  final TextEditingController controller = TextEditingController();
  bool isSending = false;

  SelectedGif? selectedGif;

  Stream<QuerySnapshot> get postsStream => _feedService.getPostsStream();

  void setSelectedGif(SelectedGif gif) {
    selectedGif = gif;
    notifyListeners();
  }

  void removeSelectedGif() {
    selectedGif = null;
    notifyListeners();
  }

  Future<String?> sendPost({List<String> tags = const []}) async {
    final text = controller.text.trim();

    if (text.isEmpty && selectedGif == null) {
      return 'Bitte gib einen Text ein oder wähle ein GIF aus.';
    }

    try {
      isSending = true;
      notifyListeners();

      await _feedService.addPost(
        text,
        gif: selectedGif,
        tags: tags,
      );

      controller.clear();
      selectedGif = null;

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