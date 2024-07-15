import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:map_tracker/widgets/weather_widget.dart';
import 'package:map_tracker/screens/profile_screen.dart';
import 'package:map_tracker/screens/new_activity_screen.dart';
import 'package:map_tracker/screens/activity_record_screen.dart';
import 'package:map_tracker/screens/partials/navbar.dart'; // Import the BottomNavBar widget
import 'package:map_tracker/screens/partials/appbar.dart'; // Import the CustomAppBar widget
import 'package:map_tracker/screens/stat_page.dart'; // Import the ActivityHistoryScreen widget
import 'package:map_tracker/model/user_model.dart'; // Import the User model
import 'package:map_tracker/services/local_db_service.dart'; // Import the DatabaseHelper

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  DatabaseHelper dbHelper = DatabaseHelper();
  User? localUser;
  firebase_auth.User? firebaseUser;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    User? userFromDb = await dbHelper.getCurrentUser();
    setState(() {
      localUser = userFromDb;
      firebaseUser = _firebaseAuth.currentUser;
    });
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      if (_selectedIndex != 2) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NewActivityScreen()),
        ).then((_) {
          setState(() {
            _selectedIndex = 0;
          });
        });
      }
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: _selectedIndex == 0
            ? CustomAppBar(
          title: "Ana Sayfa",
          automaticallyImplyLeading: false,
        )
            : null,
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHomeScreen(),
            StatisticPage(user: firebaseUser!),

            NewActivityScreen(),

            ActivityHistoryScreen(),
            ProfilePage(user:  firebaseUser!),
          ],
        ),
        extendBody: true,
        bottomNavigationBar: BottomNavBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        ),
      ),
    );
  }

  Widget _buildHomeScreen() {
    final displayName = localUser?.firstName != null && localUser?.lastName != null
        ? "${localUser!.firstName} ${localUser!.lastName}"
        : firebaseUser?.displayName ?? 'Misafir';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildUserInfo(),
        Expanded(
          child: Center(
            child: Text("Hoşgeldin! $displayName"),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (localUser != null)
            ListTile(
              title: Text("Adı Soyad: ${localUser!.firstName} ${localUser!.lastName}"),
              subtitle: Text("Email: ${localUser!.email}"),
              leading: CircleAvatar(
                child: const Icon(Icons.person),
              ),
            )
          else if (firebaseUser != null)
            ListTile(
              title: Text("Kullanıcı Adı: ${firebaseUser!.displayName ?? 'Bilinmiyor'}"),
              subtitle: Text("Email: ${firebaseUser!.email}"),
              leading: CircleAvatar(
                backgroundImage: firebaseUser!.photoURL != null ? NetworkImage(firebaseUser!.photoURL!) : null,
                child: firebaseUser!.photoURL == null ? const Icon(Icons.person) : null,
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Giriş Yapılmadı"),
            ),
          _buildWeatherWidget(),
        ],
      ),
    );
  }

  Widget _buildWeatherWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: WeatherWidget(),
    );
  }
}
