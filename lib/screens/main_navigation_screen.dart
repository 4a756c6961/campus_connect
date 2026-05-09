import 'package:flutter/material.dart';
import 'package:campus_connect/screens/home_screen.dart';
import 'package:campus_connect/screens/profil_screen.dart';
import 'package:campus_connect/screens/create_post_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  static const routeName = '/main-navigation';

  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [HomeScreen(), CreatePostScreen(), ProfilScreen()];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.feed), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.add),  label:'Beitrag'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          
        ],
      ),
    );
  }
}
