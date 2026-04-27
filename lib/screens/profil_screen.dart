import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'wird geladen...';
    return DateFormat('dd.MM.yyyy, HH:mm').format(timestamp.toDate());
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
                CircleAvatar(radius: 40, child: Text(initial)),

                const SizedBox(height: 16),

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
