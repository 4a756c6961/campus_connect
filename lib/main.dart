import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:giphy_flutter_sdk/giphy_flutter_sdk.dart';
import 'providers/auth.dart';
import 'screens/auth_gate.dart';
import 'screens/auth_screen.dart';
import 'screens/main_navigation_screen.dart';


void _configureGiphy() {
  try {
    String apiKey = '';

    if (Platform.isAndroid) {
      apiKey = const String.fromEnvironment('GIPHY_ANDROID_API_KEY');
    } else if (Platform.isIOS) {
      apiKey = const String.fromEnvironment('GIPHY_IOS_API_KEY');
    } else {
      if (kDebugMode) {
        print('GIPHY wird auf dieser Plattform nicht unterstützt.');
      }
      return;
    }

    if (apiKey.isEmpty) {
      if (kDebugMode) {
        print('Kein GIPHY API Key gesetzt.');
      }
      return;
    }

    GiphyFlutterSDK.configure(apiKey: apiKey);
  } catch (e) {
    if (kDebugMode) {
      print('GIPHY konnte nicht initialisiert werden: $e');
    }
  }
}



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  _configureGiphy();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider<Auth>(create: (_) => Auth())],
      child: MaterialApp(
        title: 'Campus Connect',
        theme: ThemeData(primarySwatch: Colors.deepOrange, fontFamily: 'Lato'),
        home: const AuthGate(),
        routes: {
          AuthScreen.routeName: (_) => const AuthScreen(),
          MainNavigationScreen.routeName: (_) => const MainNavigationScreen(),
        },
      ),
    );
  }
}
