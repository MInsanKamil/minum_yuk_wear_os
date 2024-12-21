import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    Center(child: Text('Riwayat', style: TextStyle(color: Colors.white))),
    Center(child: Text('Profil', style: TextStyle(color: Colors.white))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Stack(
          children: [
            // Lingkaran dengan konten layar
            Center(
              // Diameter lingkaran
              child: _screens[_currentIndex], // Konten layar
            ),

            // Tombol Hamburger Menu (di luar lingkaran)
            Positioned(
              top: MediaQuery.of(context).padding.top + 25, // Jarak dari atas
              left: 25, // Jarak dari kiri
              child: IconButton(
                icon: Icon(Icons.menu, color: Colors.white, size: 30),
                onPressed: () => _showDrawer(context), // Tampilkan drawer
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.blueGrey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.home, color: Colors.white),
            title: Text('Home', style: TextStyle(color: Colors.white)),
            onTap: () {
              setState(() {
                _currentIndex = 0;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.history, color: Colors.white),
            title: Text('Riwayat', style: TextStyle(color: Colors.white)),
            onTap: () {
              setState(() {
                _currentIndex = 1;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.person, color: Colors.white),
            title: Text('Profil', style: TextStyle(color: Colors.white)),
            onTap: () {
              setState(() {
                _currentIndex = 2;
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
