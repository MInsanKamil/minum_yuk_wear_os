import 'package:flutter/material.dart';
// import 'screens/reminder_screen.dart';
import 'screens/profil_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    HistoryScreen(),
    ProfileScreen(),
    // ReminderSettingsScreen()
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

            // Tombol Hamburger Menu (posisi dinamis berdasarkan _currentIndex)
            Align(
              alignment: _currentIndex == 1 || _currentIndex == 2
                  ? const Alignment(0.0,
                      -1.08) // Posisi di atas tengah untuk _currentIndex == 1
                  : Alignment.centerRight, // Posisi default di kanan tengah
              child: IconButton(
                icon: Icon(Icons.menu,
                    color: _currentIndex == 1 || _currentIndex == 2
                        ? Colors.white // Warna putih untuk _currentIndex == 1
                        : const Color.fromARGB(255, 36, 109, 143),
                    size: _currentIndex == 1 ? 25 : 30),
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
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(120), // Efek setengah lingkaran
        ),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Center(
          // Membuat semua isi berada di tengah
          child: Column(
            mainAxisSize:
                MainAxisSize.min, // Menyesuaikan ukuran column dengan isi
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentIndex = 0;
                  });
                  Navigator.pop(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center, // Pusatkan konten
                    children: [
                      Icon(Icons.home, color: Colors.white),
                      SizedBox(width: 5),
                      Text('Home', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentIndex = 1;
                  });
                  Navigator.pop(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center, // Pusatkan konten
                    children: [
                      Icon(Icons.history, color: Colors.white),
                      SizedBox(width: 5),
                      Text('Riwayat', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentIndex = 2;
                  });
                  Navigator.pop(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center, // Pusatkan konten
                    children: [
                      Icon(Icons.person, color: Colors.white),
                      SizedBox(width: 5),
                      Text('Profil', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
              // GestureDetector(
              //   onTap: () {
              //     setState(() {
              //       _currentIndex = 3;
              //     });
              //     Navigator.pop(context);
              //   },
              //   child: Padding(
              //     padding: const EdgeInsets.symmetric(
              //         vertical: 5.0, horizontal: 16.0),
              //     child: Row(
              //       mainAxisAlignment: MainAxisAlignment.center,
              //       children: [
              //         Icon(Icons.alarm, color: Colors.white),
              //         SizedBox(width: 5),
              //         Text('Atur Pengingat',
              //             style: TextStyle(color: Colors.white)),
              //       ],
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
