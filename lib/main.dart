import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'providers/auth.dart';
import 'screens/auth_gate.dart';
import 'screens/auth_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
          // HomeScreen.routeName: (_) => const HomeScreen(),  // falls du es nutzt
        },
      ),
    );
  }
}
