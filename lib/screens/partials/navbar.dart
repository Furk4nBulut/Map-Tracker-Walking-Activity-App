import 'package:flutter/material.dart';
import 'package:map_tracker/utils/constants.dart';
class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const BottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Ana Sayfa',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline),
          label: 'Aktivite Ekle',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'Geçmiş',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profil',
        ),
        ],
    currentIndex: selectedIndex,
    selectedItemColor: Colors.white,
    unselectedItemColor: Colors.white.withOpacity(0.7),
    onTap: onItemTapped,
      // 2, 32, 92 rgb color
      backgroundColor: basarsoft_color,
    elevation: 0,
    type: BottomNavigationBarType.fixed,
    selectedLabelStyle: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 14,
    ),
    unselectedLabelStyle: TextStyle(
    fontWeight: FontWeight.normal,
    fontSize: 12,
    ),
    iconSize: 28,
    );
  }
}