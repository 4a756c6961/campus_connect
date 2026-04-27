import 'dart:io';

import 'package:characters/characters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  bool _isUploading = false;

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'wird geladen...';
    return DateFormat('dd.MM.yyyy, HH:mm').format(timestamp.toDate());
  }

  Future<void> _pickAndUploadProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final picker = ImagePicker();

    final pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 600,
    );

    if (pickedImage == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final imageFile = File(pickedImage.path);

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profilePictures')
          .child(user.uid)
          .child('profile.jpg');

      await storageRef.putFile(imageFile);

      final downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'photoUrl': downloadUrl},
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profilbild wurde aktualisiert.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fehler beim Hochladen: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Mein Profil')),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;

          final displayName = (data?['displayName'] ?? '').toString();
          final email = (data?['email'] ?? user?.email ?? '').toString();
          final photoUrl = (data?['photoUrl'] ?? '').toString();

          final initial =
              displayName.trim().isNotEmpty
                  ? displayName.trim().characters.first.toUpperCase()
                  : email.trim().isNotEmpty
                  ? email.trim().characters.first.toUpperCase()
                  : '?';

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage:
                      photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                  child: photoUrl.isEmpty ? Text(initial) : null,
                ),

                const SizedBox(height: 8),

                TextButton.icon(
                  onPressed: _isUploading ? null : _pickAndUploadProfileImage,
                  icon:
                      _isUploading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.camera_alt),
                  label: Text(
                    _isUploading ? 'Lade hoch...' : 'Profilbild ändern',
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  displayName.isNotEmpty ? displayName : 'Kein Anzeigename',
                  style: const TextStyle(fontSize: 18),
                ),

                const SizedBox(height: 8),

                Text(
                  email.isNotEmpty ? email : 'Keine E-Mail',
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 24),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Meine Beiträge',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('posts')
                            .where('userId', isEqualTo: user?.uid)
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                    builder: (context, postSnapshot) {
                      if (postSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (postSnapshot.hasError) {
                        return Center(
                          child: Text('Fehler: ${postSnapshot.error}'),
                        );
                      }

                      final docs = postSnapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return const Center(
                          child: Text('Du hast noch keine Beiträge erstellt.'),
                        );
                      }

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final postData = doc.data() as Map<String, dynamic>;

                          final text = (postData['text'] ?? '').toString();
                          final createdAtRaw = postData['createdAt'];
                          final createdAt =
                              createdAtRaw is Timestamp ? createdAtRaw : null;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(text),
                              subtitle: Text(_formatTimestamp(createdAt)),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
