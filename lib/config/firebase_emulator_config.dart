import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

const bool useFirebaseEmulators = bool.fromEnvironment(
  'USE_FIREBASE_EMULATORS',
  defaultValue: false,
);

const String firebaseEmulatorHost = String.fromEnvironment(
  'FIREBASE_EMULATOR_HOST',
  defaultValue: '127.0.0.1',
);

Future<void> configureFirebaseEmulators() async {
  if (!kDebugMode || !useFirebaseEmulators) {
    debugPrint('🔥 Firebase Emulatoren: AUS');
    return;
  }

  debugPrint(
    '🧪 Firebase Emulatoren: AN - Host $firebaseEmulatorHost',
  );

  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  final functions = FirebaseFunctions.instance;

  await auth.useAuthEmulator(
    firebaseEmulatorHost,
    9099,
  );

  firestore.settings = const Settings(
    persistenceEnabled: false,
  );

  firestore.useFirestoreEmulator(
    firebaseEmulatorHost,
    8080,
  );

  functions.useFunctionsEmulator(
    firebaseEmulatorHost,
    5001,
  );

  // Einen eventuell gespeicherten Login aus der
  // produktiven Firebase nicht in den Test übernehmen.
  await auth.signOut();
}