import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  final FirebaseMessaging _messaging;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  PushNotificationService({
    FirebaseMessaging? messaging,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  void initialize() {
    _authSubscription = _auth.authStateChanges().listen((user) async {
      if (user == null) {
        debugPrint('Kein Nutzer angemeldet – FCM-Token wird nicht gespeichert.');
        return;
      }

      await _registerDevice(user.uid);
    });

    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
      (token) async {
        final user = _auth.currentUser;

        if (user == null) {
          return;
        }

        await _saveToken(
          userId: user.uid,
          token: token,
        );
      },
      onError: (Object error) {
        debugPrint('Fehler beim Aktualisieren des FCM-Tokens: $error');
      },
    );
  }

  Future<void> _registerDevice(String userId) async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      debugPrint('Push-Benachrichtigungen wurden nicht erlaubt.');
      return;
    }

    final token = await _messaging.getToken();

    if (token == null || token.isEmpty) {
      debugPrint('Es konnte kein FCM-Token abgerufen werden.');
      return;
    }

    await _saveToken(
      userId: userId,
      token: token,
    );
  }

  Future<void> _saveToken({
    required String userId,
    required String token,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('fcmTokens')
        .doc(token)
        .set({
          'token': token,
          'platform': defaultTargetPlatform.name,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    debugPrint('FCM-Token wurde in Firestore gespeichert.');
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _tokenRefreshSubscription?.cancel();
  }
}