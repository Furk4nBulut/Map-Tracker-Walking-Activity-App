import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:map_tracker/widgets/weather_widget.dart';
import 'package:map_tracker/screens/profile_screen.dart';
import 'package:map_tracker/screens/new_activity_screen.dart';
import 'package:map_tracker/screens/activity_record_screen.dart';
import 'package:map_tracker/screens/partials/navbar.dart'; // Import the BottomNavBar widget
import 'package:map_tracker/screens/partials/appbar.dart'; // Import the CustomAppBar widget
import 'package:map_tracker/screens/stat_page.dart'; // Import the ActivityHistoryScreen widget
import 'package:map_tracker/model/user_model.dart'; // Import the User model
import 'package:map_tracker/services/local_db_service.dart'; // Import the DatabaseHelper
import 'package:map_tracker/screens/welcome_screen.dart'; // Import the WelcomeScreen
import 'package:map_tracker/screens/welcome_screen.dart'; // Import the WelcomeScreen

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DatabaseHelper dbHelper = DatabaseHelper();
  LocalUser? localUser;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    LocalUser? userFromDb = await dbHelper.getCurrentUser();
    if (userFromDb == null) {
      // Navigate to WelcomeScreen if no user is found
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WelcomeScreen()),
      );
      Fluttertoast.showToast(msg: "Kullanıcı bulunamadı. Lütfen giriş yapın.", toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM, timeInSecForIosWeb: 1, backgroundColor: Colors.red, textColor: Colors.white, fontSize: 16.0); // Add this line

    } else {
      setState(() {
        localUser = userFromDb;
      });
    }
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
            StatisticPage(), // You can pass null here or handle differently if user is not logged in

            NewActivityScreen(),

            ActivityHistoryScreen(),
            ProfilePage(), // You can pass null here or handle differently if user is not logged in
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
        : 'Misafir'; // Default guest name or handle differently if not logged in

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
