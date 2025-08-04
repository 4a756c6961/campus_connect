import 'package:campus_connect/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'screens/auth_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Connect',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.deepOrange,
        ).copyWith(secondary: Colors.deepPurple),
        fontFamily: 'Lato',
      ),
      home: AuthScreen(), // <--- Start der App mit dem AuthScreen
      routes: {
        AuthScreen.routeName: (ctx) => AuthScreen(),
        //HomeScreen.routeName: (ctx) => HomeScreen(),
        // hier werden weitere Screens eingetragen
      },
    );
  }
}
