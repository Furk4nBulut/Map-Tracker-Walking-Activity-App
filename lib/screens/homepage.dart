import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:map_tracker/widgets/weather_widget.dart';
import 'package:map_tracker/screens/profile_screen.dart';
import 'package:map_tracker/screens/new_activity_screen.dart';
import 'package:map_tracker/screens/activity_record_screen.dart';
import 'package:map_tracker/screens/stat_page.dart';
import 'package:map_tracker/screens/partials/navbar.dart';
import 'package:map_tracker/screens/partials/appbar.dart';
import 'package:map_tracker/model/user_model.dart';
import 'package:map_tracker/services/local_db_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DatabaseHelper dbHelper = DatabaseHelper();
  LocalUser? localUser;
  User? firebaseUser;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    LocalUser? userFromDb = await dbHelper.getCurrentUser();
    setState(() {
      localUser = userFromDb;
      firebaseUser = FirebaseAuth.instance.currentUser;
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
            StatisticPage(),
            NewActivityScreen(),
            ActivityHistoryScreen(),
            ProfilePage(),
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
        : firebaseUser?.displayName ?? "Misafir";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildWeatherWidget(),
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
              title: Text("Email: ${localUser!.email}"),
              leading: CircleAvatar(
                child: const Icon(Icons.person),
              ),
            )
          else if (firebaseUser != null)
            ListTile(
              title: Text("Adı Soyad: ${firebaseUser!.displayName}"),
              subtitle: Text("Email: ${firebaseUser!.email}"),
              leading: CircleAvatar(
                backgroundImage: NetworkImage(firebaseUser!.photoURL ?? ''),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Giriş Yapılmadı"),
            ),
        ],
      ),
    );
  }

  Widget _buildWeatherWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      child: WeatherWidget(),
    );
  }
}
