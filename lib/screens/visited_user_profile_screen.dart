import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VisitedUserProfileScreen extends StatelessWidget {
  final String userId;

  const VisitedUserProfileScreen({super.key, required this.userId});

  String _getDisplayName(Map<String, dynamic> data) {
    return (data['displayName'] ??
            data['userName'] ??
            data['name'] ??
            'Unbekannter Nutzer')
        .toString();
  }

  String _getPhotoUrl(Map<String, dynamic> data) {
    return (data['photoUrl'] ?? '').toString();
  }

  String _getBio(Map<String, dynamic> data) {
    return (data['bio'] ?? 'Noch keine Profilbeschreibung vorhanden.')
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(userId).snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: userDoc,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Profil konnte nicht geladen werden.'),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Profil nicht gefunden.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final displayName = _getDisplayName(data);
          final photoUrl = _getPhotoUrl(data);
          final bio = _getBio(data);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 54,
                  backgroundImage:
                      photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                  child:
                      photoUrl.isEmpty
                          ? const Icon(Icons.person, size: 54)
                          : null,
                ),
                const SizedBox(height: 16),
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Über mich',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    bio,
                    style: Theme.of(context).textTheme.bodyLarge,
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
