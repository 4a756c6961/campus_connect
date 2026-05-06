import 'package:flutter/material.dart';
import 'package:campus_connect/services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentDisplayName;
  final String currentBio;
  final String currentLocation;
  final String currentCohort;

  const EditProfileScreen({
    super.key,
    required this.currentDisplayName,
    required this.currentBio,
    required this.currentLocation,
    required this.currentCohort,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ProfileService _profileService = ProfileService();

  late final TextEditingController _displayNameController;
  late final TextEditingController _bioController;
  late final TextEditingController _locationController;
  late final TextEditingController _cohortController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _displayNameController = TextEditingController(
      text: widget.currentDisplayName,
    );
    _bioController = TextEditingController(text: widget.currentBio);
    _locationController = TextEditingController(text: widget.currentLocation);
    _cohortController = TextEditingController(text: widget.currentCohort);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _cohortController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final displayName = _displayNameController.text.trim();

    if (displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gib einen Anzeigenamen ein.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _profileService.updateProfileFields(
        displayName: displayName,
        bio: _bioController.text,
        location: _locationController.text,
        cohort: _cohortController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil wurde gespeichert.')),
      );

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fehler beim Speichern: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil bearbeiten'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child:
                _isSaving
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Speichern'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Anzeigename',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Bio',
                hintText: 'Erzähl kurz etwas über dich...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Standort',
                hintText: 'z. B. Rostock, Köln, Berlin',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cohortController,
              decoration: const InputDecoration(
                labelText: 'Kohorte',
                hintText: 'z. B. AI 2024, BWL 2023',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
