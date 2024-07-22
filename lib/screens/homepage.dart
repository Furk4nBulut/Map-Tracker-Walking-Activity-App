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

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 70.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildWeatherWidget(),
            _buildSectionDivider(),
            _buildUserInfo(),
            _buildSectionDivider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: RichText(
                textAlign: TextAlign.justify,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "Bu uygulama, yürüyüş ve koşu aktivitelerinizi daha etkili bir şekilde yönetmenize yardımcı olur. İşte uygulamanın sunduğu bazı özellikler:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    TextSpan(
                      text: "\n\n",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                    WidgetSpan(
                      child: Icon(Icons.location_on, color: Colors.blue[800], size: 20),
                    ),
                    TextSpan(
                      text: " Yürüyüş ve koşu aktivitelerinizi takip eder: ",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    TextSpan(
                      text: "Uygulama, başladığınız her yeni yürüyüş veya koşu aktivitesinde mevcut konumunuzu GPS üzerinden takip eder ve harita üzerinde rotanızı çizer.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                    TextSpan(
                      text: "\n\n",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                    WidgetSpan(
                      child: Icon(Icons.access_time, color: Colors.green[800], size: 20),
                    ),
                    TextSpan(
                      text: " Anlık veri görüntüleme: ",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    TextSpan(
                      text: "Aktivite sırasında kaydedilen mesafe, süre ve ortalama hız gibi bilgileri anlık olarak görüntüleyebilirsiniz.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                    TextSpan(
                      text: "\n\n",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                    WidgetSpan(
                      child: Icon(Icons.storage, color: Colors.orange[800], size: 20),
                    ),
                    TextSpan(
                      text: " Veri kaydetme ve analiz: ",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    TextSpan(
                      text: "Aktivitenizi tamamladığınızda, bu bilgiler uygulama içindeki veritabanına kaydedilir. Daha sonra bu verileri gözden geçirebilir, analiz edebilir ve geçmiş aktivitelerinizi detaylı bir şekilde inceleyebilirsiniz.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                    TextSpan(
                      text: "\n\n",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                    WidgetSpan(
                      child: Icon(Icons.wb_sunny, color: Colors.yellow[800], size: 20),
                    ),
                    TextSpan(
                      text: " Hava durumu bilgileri: ",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    TextSpan(
                      text: "Uygulama, hava durumu bilgilerini sunarak hava koşullarına göre planlama yapmanıza olanak tanır.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                    TextSpan(
                      text: "\n\nUygulama sayesinde, hem mevcut hem de geçmiş aktivitelerinizle ilgili kapsamlı bilgiler edinerek spor alışkanlıklarınızı daha etkin bir şekilde yönetebilirsiniz.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildSectionDivider(),
          ],
        ),
      ),
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
              title: Text(
                "Email: ${localUser!.email}",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              leading: CircleAvatar(
                child: const Icon(Icons.person),
              ),
            )
          else if (firebaseUser != null)
            ListTile(
              title: Text(
                "Adı Soyad: ${firebaseUser!.displayName}",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                "Email: ${firebaseUser!.email}",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              leading: CircleAvatar(
                backgroundImage: NetworkImage(firebaseUser!.photoURL ?? ''),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Giriş Yapılmadı",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
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

  Widget _buildSectionDivider() {
    return Divider(
      color: Colors.blue[800],
      thickness: 1,
      indent: 16,
      endIndent: 16,
    );
  }
}
