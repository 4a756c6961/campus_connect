import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:campus_connect/widgets/user_posts_section.dart';

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
    return (data['bio'] ?? '').toString().trim();
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
          final location = (data['location'] ?? '').toString().trim();
          final cohort = (data['cohort'] ?? '').toString().trim();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
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

                const SizedBox(height: 32),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Über mich',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    bio.isNotEmpty
                        ? bio
                        : 'Noch keine Profilbeschreibung vorhanden.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),

                if (location.isNotEmpty || cohort.isNotEmpty) ...[
                  const SizedBox(height: 20),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (location.isNotEmpty)
                          Chip(
                            avatar: const Icon(Icons.location_on, size: 18),
                            label: Text(location),
                          ),

                        if (cohort.isNotEmpty)
                          Chip(
                            avatar: const Icon(Icons.school, size: 18),
                            label: Text(cohort),
                          ),
                        const SizedBox(height: 24),

                        UserPostsSection(userId: userId, title: 'Beiträge'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
