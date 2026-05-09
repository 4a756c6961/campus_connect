import 'package:flutter/material.dart';
import 'package:campus_connect/widgets/post_input.dart';

class CreatePostScreen extends StatelessWidget {
  const CreatePostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neuen Beitrag erstellen'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: PostInput(),
      ),
    );
  }
}