import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  Future<XFile?> pickProfileImage() async {
    return _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 800,
    );
  }

  Future<String?> pickAndUploadProfileImage() async {
    final pickedImage = await pickProfileImage();

    if (pickedImage == null) {
      return null;
    }

    final imageFile = File(pickedImage.path);

    return uploadProfileImage(imageFile);
  }

  Future<String> uploadProfileImage(File imageFile) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Kein eingeloggter Benutzer gefunden.');
    }

    final storageRef = _storage
        .ref()
        .child('profile_images')
        .child(user.uid)
        .child('profile.jpg');

    await storageRef.putFile(imageFile);

    final downloadUrl = await storageRef.getDownloadURL();

    await _firestore.collection('users').doc(user.uid).set({
      'photoUrl': downloadUrl,
    }, SetOptions(merge: true));

    return downloadUrl;
  }

  Future<void> deleteProfileImage() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Kein eingeloggter Benutzer gefunden.');
    }

    final userDocRef = _firestore.collection('users').doc(user.uid);
    final userDoc = await userDocRef.get();

    final data = userDoc.data();
    final photoUrl = data?['photoUrl'] as String?;

    if (photoUrl != null && photoUrl.isNotEmpty) {
      try {
        final imageRef = _storage.refFromURL(photoUrl);
        await imageRef.delete();
      } on FirebaseException catch (e) {
        if (e.code != 'object-not-found') {
          rethrow;
        }
      }
    }

    await userDocRef.update({'photoUrl': FieldValue.delete()});
  }

  Future<void> updateProfileFields({
    required String displayName,
    required String bio,
    required String location,
    required String cohort,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Kein eingeloggter Nutzer gefunden.');
    }

    await _firestore.collection('users').doc(user.uid).set({
      'displayName': displayName.trim(),
      'bio': bio.trim(),
      'location': location.trim(),
      'cohort': cohort.trim(),
      'email': user.email,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
