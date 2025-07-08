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
import 'package:easy_localization/easy_localization.dart';
import 'package:map_tracker/localization/locale_keys.g.dart';
import 'package:map_tracker/widgets/admob_banner.dart';
import 'package:map_tracker/widgets/app_banner_ad.dart';
import 'package:map_tracker/utils/constants.dart';
import 'package:map_tracker/screens/ads_screen.dart';
import 'package:map_tracker/services/ad_service.dart';

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
  static int homePageVisitCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    homePageVisitCount++;
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
          title: LocaleKeys.homeTitle.tr(),
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
            AppBannerAd(),
            _buildSectionDivider(),
            _buildUserInfo(),
            _buildSectionDivider(),
            _buildAppIntroSection(context), // Tanıtım yazısı butondan önceye alındı
            _buildSectionDivider(),
            _buildSupportDevButton(context), // Destekle butonu en alta alındı
            SizedBox(height: 32), // Navbar ile arasında ekstra boşluk
          ],
        ),
      ),
    );
  }

  Widget _buildSupportDevButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 18),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: Icon(Icons.volunteer_activism, color: Colors.white, size: 26),
          label: Text(
            LocaleKeys.ad_info_support.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: basarsoft_color,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0),
            ),
            elevation: 3,
            shadowColor: basarsoft_color.withOpacity(0.10),
          ),
          onPressed: () {
            AdService.showInterstitialAd(
              context,
              onClosed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdsScreen()));
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppIntroSection(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: RichText(
        textAlign: TextAlign.justify,
        text: TextSpan(
          children: [
            TextSpan(
              text: LocaleKeys.appDescription.tr(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            TextSpan(
              text: "\n\n",
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            WidgetSpan(
              child: Icon(Icons.location_on, color: Colors.blue[800], size: 20),
            ),
            TextSpan(
              text: " ${LocaleKeys.featureTrackingTitle.tr()}: ",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            TextSpan(
              text: LocaleKeys.featureTrackingDescription.tr(),
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            TextSpan(
              text: "\n\n",
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            WidgetSpan(
              child: Icon(Icons.access_time, color: Colors.green[800], size: 20),
            ),
            TextSpan(
              text: " ${LocaleKeys.featureRealTimeDataTitle.tr()}: ",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            TextSpan(
              text: LocaleKeys.featureRealTimeDataDescription.tr(),
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            TextSpan(
              text: "\n\n",
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            WidgetSpan(
              child: Icon(Icons.storage, color: Colors.orange[800], size: 20),
            ),
            TextSpan(
              text: " ${LocaleKeys.featureDataStorageTitle.tr()}: ",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            TextSpan(
              text: LocaleKeys.featureDataStorageDescription.tr(),
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            TextSpan(
              text: "\n\n",
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            WidgetSpan(
              child: Icon(Icons.wb_sunny, color: Colors.yellow[800], size: 20),
            ),
            TextSpan(
              text: " ${LocaleKeys.featureWeatherTitle.tr()}: ",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            TextSpan(
              text: LocaleKeys.featureWeatherDescription.tr(),
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            TextSpan(
              text: "\n\n${LocaleKeys.appSummary.tr()}",
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
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
                "${LocaleKeys.emailField.tr()}: ${localUser!.email}",
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
                "${LocaleKeys.fullName.tr()}: ${firebaseUser!.displayName}",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                "${LocaleKeys.emailField.tr()}: ${firebaseUser!.email}",
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
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                LocaleKeys.notSignedIn.tr(),
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