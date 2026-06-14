import 'package:characters/characters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:campus_connect/screens/visited_user_profile_screen.dart';
import 'package:campus_connect/services/user_search_service.dart';

class SearchScreen extends StatefulWidget {
  static const routeName = '/search';

  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final UserSearchService _userSearchService = UserSearchService();

  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getInitial(String displayName) {
    final trimmedName = displayName.trim();

    if (trimmedName.isEmpty) {
      return '?';
    }

    return trimmedName.characters.first.toUpperCase();
  }

  String _getDisplayName(Map<String, dynamic> data) {
    return (data['displayName'] ??
            data['userName'] ??
            data['name'] ??
            'Unbekannter Nutzer')
        .toString();
  }

  String _buildSubtitle(Map<String, dynamic> data) {
    final userName = (data['userName'] ?? '').toString();
    final location = (data['location'] ?? '').toString();
    final cohort = (data['cohort'] ?? '').toString();

    final subtitleParts = [
      if (userName.isNotEmpty) '@$userName',
      if (location.isNotEmpty) location,
      if (cohort.isNotEmpty) cohort,
    ];

    if (subtitleParts.isEmpty) {
      return 'Keine weiteren Angaben';
    }

    return subtitleParts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchText.trim();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Suche')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              // Tastatur schließen, wenn außerhalb des Suchfeldes getippt wird
              onTapOutside: (_) {
                FocusScope.of(context).unfocus();
              },
              decoration: InputDecoration(
                hintText: 'Name, Standort oder Kohorte suchen',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    query.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          // Suchfeld leeren + Tastatur schließen
                          onPressed: () {
                            _searchController.clear();
                            FocusScope.of(context).unfocus();

                            setState(() {
                              _searchText = '';
                            });
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),

              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildSearchContent(
                query: query,
                currentUserId: currentUserId,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchContent({
    required String query,
    required String? currentUserId,
  }) {
    if (query.isEmpty) {
      return const Center(
        child: Text(
          'Suche nach Namen, Standort oder Kohorte.',
          textAlign: TextAlign.center,
        ),
      );
    }

    if (query.length < 2) {
      return const Center(
        child: Text(
          'Gib mindestens 2 Zeichen ein.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _userSearchService.searchUsers(query),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Beim Suchen ist ein Fehler aufgetreten.',
              textAlign: TextAlign.center,
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        final filteredDocs =
            docs.where((doc) {
              return doc.id != currentUserId;
            }).toList();

        if (filteredDocs.isEmpty) {
          return const Center(
            child: Text(
              'Keine passenden Profile gefunden.',
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.separated(
          itemCount: filteredDocs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data();

            final displayName = _getDisplayName(data);
            final subtitle = _buildSubtitle(data);
            final photoUrl = (data['photoUrl'] ?? '').toString();

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 8,
              ),
              leading: CircleAvatar(
                radius: 24,
                backgroundImage:
                    photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child:
                    photoUrl.isEmpty
                        ? Text(
                          _getInitial(displayName),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                        : null,
              ),
              title: Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                FocusScope.of(context).unfocus();

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VisitedUserProfileScreen(userId: doc.id),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
