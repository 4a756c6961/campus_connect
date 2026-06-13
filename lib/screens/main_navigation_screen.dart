import 'package:flutter/material.dart';
import 'package:campus_connect/screens/home_screen.dart';
import 'package:campus_connect/screens/profil_screen.dart';
import 'package:campus_connect/screens/create_post_screen.dart';
import 'package:campus_connect/screens/search_screen.dart';
import 'package:provider/provider.dart';
import 'package:campus_connect/services/feed_service.dart';
import 'package:campus_connect/providers/feed_provider.dart';

class MainNavigationScreen extends StatefulWidget {
    static const routeName = '/main-navigation';

  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    CreatePostScreen(),
    SearchScreen(),
    ProfilScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FeedProvider(FeedService()),
      child: Scaffold(
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,

         type: BottomNavigationBarType.fixed,

          backgroundColor: const Color(0xFFFFF7FF),
          selectedItemColor: const Color(0xFF6750A4),
          unselectedItemColor: const Color(0xFF6F6A72),

          selectedFontSize: 13,
          unselectedFontSize: 13,
          showSelectedLabels: true,
          showUnselectedLabels: true,

          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.feed),
              label: 'Feed',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add),
              label: 'Beitrag',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Suche',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}