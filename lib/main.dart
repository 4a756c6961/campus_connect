import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'providers/auth.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // falls Firebase genutzt wird
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
        theme: ThemeData(
          // Alternativ moderner:
          // colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
          primarySwatch: Colors.deepOrange,
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.deepOrange,
          ).copyWith(secondary: Colors.deepPurple),
          fontFamily: 'Lato',
        ),
        home: const AuthScreen(), // Start mit AuthScreen
        routes: {AuthScreen.routeName: (ctx) => const AuthScreen()},
      ),
    );
  }
}
