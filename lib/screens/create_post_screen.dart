import 'package:flutter/material.dart';
import 'package:campus_connect/widgets/post_input.dart';

class CreatePostScreen extends StatelessWidget {
  final VoidCallback? onPostCreated;

  const CreatePostScreen({
    super.key,
    this.onPostCreated,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neuen Beitrag erstellen'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(16),
          child: PostInput(
            onPostCreated: onPostCreated,
          ),
        ),
      ),
    );
  }
}