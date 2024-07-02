import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:map_tracker/services/auth_service.dart';
import 'profile_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final User? user = ModalRoute.of(context)?.settings.arguments as User?;

    List<Widget> _widgetOptions = <Widget>[
      // Ana içerik
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (user != null)
              Column(
                children: [
                  ListTile(
                    title: Text("Kullanıcı Adı: ${user.displayName ?? 'Bilinmiyor'}"),
                    subtitle: Text("Email: ${user.email}"),
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(user.photoURL ?? ""),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Genel Profil ve Spor Durumu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8.0),
                          Text("Toplam Yapılan Mesafe: 120 km"),
                          Text("Toplam Süre: 10 saat"),
                          Text("Aktivite Sayısı: 25"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            if (user == null)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Giriş Yapılmadı"),
              ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/new_activity');
              },
              child: Text("Yeni Aktivite"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/activity_history');
              },
              child: Text("Aktivite Geçmişim"),
            ),
          ],
        ),
      ),
      // Profil ekranı
      if (user != null) ProfilePage(user: user) else const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text("Giriş Yapılmadı"),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("Map Tracker App"),
        centerTitle: true,
        automaticallyImplyLeading: false, // Geri butonunu göster

        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              await AuthService().signOut();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
