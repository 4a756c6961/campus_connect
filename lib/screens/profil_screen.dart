import 'package:characters/characters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:campus_connect/services/profile_service.dart';
import 'package:campus_connect/screens/edit_profile_screen.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final ProfileService _profileService = ProfileService();

  bool _isUploading = false;
  bool _isDeleting = false;

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'wird geladen...';
    return DateFormat('dd.MM.yyyy, HH:mm').format(timestamp.toDate());
  }

  Future<void> _pickAndUploadProfileImage() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final photoUrl = await _profileService.pickAndUploadProfileImage();

      if (!mounted) return;

      // User hat Bildauswahl abgebrochen
      if (photoUrl == null) return;

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

  Future<void> _confirmDeleteProfileImage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Profilbild löschen?'),
          content: const Text(
            'Möchtest du dein Profilbild wirklich entfernen?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Löschen'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _deleteProfileImage();
  }

  Future<void> _deleteProfileImage() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      await _profileService.deleteProfileImage();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profilbild wurde gelöscht.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fehler beim Löschen: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Du bist nicht eingeloggt.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mein Profil')),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;

          final displayName = (data?['displayName'] ?? '').toString();
          final email = (data?['email'] ?? user.email ?? '').toString();
          final photoUrl = (data?['photoUrl'] ?? '').toString();
          final bio = (data?['bio'] ?? '').toString();
          final location = (data?['location'] ?? '').toString();
          final cohort = (data?['cohort'] ?? '').toString();
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

                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    TextButton.icon(
                      onPressed:
                          _isUploading || _isDeleting
                              ? null
                              : _pickAndUploadProfileImage,
                      icon:
                          _isUploading
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.camera_alt),
                      label: Text(
                        _isUploading ? 'Lade hoch...' : 'Profilbild ändern',
                      ),
                    ),

                    if (photoUrl.isNotEmpty)
                      TextButton.icon(
                        onPressed:
                            _isUploading || _isDeleting
                                ? null
                                : _confirmDeleteProfileImage,
                        icon:
                            _isDeleting
                                ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.delete_outline),
                        label: Text(
                          _isDeleting ? 'Lösche...' : 'Profilbild löschen',
                        ),
                      ),
                  ],
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
                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (_) => EditProfileScreen(
                              currentDisplayName: displayName,
                              currentBio: bio,
                              currentLocation: location,
                              currentCohort: cohort,
                            ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Profil bearbeiten'),
                ),
                const SizedBox(height: 16),

                if (bio.isNotEmpty) Text(bio, textAlign: TextAlign.center),

                if (location.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Standort: $location'),
                ],

                if (cohort.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Kohorte: $cohort'),
                ],
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
                            .where('userId', isEqualTo: user.uid)
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
