import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:map_tracker/screens/activity_record_screen.dart';
import 'package:map_tracker/screens/new_activity_screen.dart';
import 'package:map_tracker/screens/partials/appbar.dart';
import 'package:map_tracker/utils/constants.dart';

class ProfilePage extends StatelessWidget {
  final User user;

  const ProfilePage({Key? key, required this.user}) : super(key: key);

  Future<Map<String, dynamic>> _fetchUserStatistics() async {
    final userActivities = FirebaseFirestore.instance
        .collection('user')
        .doc(user.uid)
        .collection('activities');

    final activitiesSnapshot = await userActivities.get();

    double totalDistance = 0.0;
    Duration totalDuration = Duration();
    int activityCount = activitiesSnapshot.size;

    for (var doc in activitiesSnapshot.docs) {
      totalDistance += doc['totalDistance'] ?? 0.0;
      Timestamp startTime = doc['startTime'];
      Timestamp endTime = doc['endTime'];
      totalDuration += endTime.toDate().difference(startTime.toDate());
    }

    double averageDistance = totalDistance / activityCount;
    Duration averageDuration = totalDuration ~/ activityCount;

    return {
      'totalDistance': totalDistance,
      'totalDuration': totalDuration,
      'averageDistance': averageDistance,
      'averageDuration': averageDuration,
      'activityCount': activityCount,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Profil", automaticallyImplyLeading: true),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchUserStatistics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
                child: Text('Bir hata oluştu: ${snapshot.error.toString()}'));
          }

          if (!snapshot.hasData) {
            return Center(child: Text('Veriler yüklenemedi.'));
          }

          Map<String, dynamic> stats = snapshot.data!;
          double totalDistance = stats['totalDistance'];
          Duration totalDuration = stats['totalDuration'];
          double averageDistance = stats['averageDistance'];
          int activityCount = stats['activityCount'];

          String formattedTotalDuration =
              "${totalDuration.inHours} saat ${totalDuration.inMinutes.remainder(60)} dakika";

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Hero(
                    tag: 'userProfileImage',
                    child: Container(
                      decoration: BoxDecoration(
                        color: basarsoft_color,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: EdgeInsets.all(2),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: user.photoURL != null
                            ? NetworkImage(user.photoURL!)
                            : null,
                        child: user.photoURL == null
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                    ),
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    user.displayName ?? 'Bilinmiyor',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    user.email ?? 'Email bilinmiyor',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Card(
                    color: Colors.white,
                    elevation: 6, // Adjusted elevation value
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                    ),
                    shadowColor: basarsoft_color,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.insert_chart_outlined,
                                size: 28,
                                semanticLabel: 'İstatistikler',
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 2,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                              SizedBox(width: 8),
                              Text(
                                "İstatistikler",
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  fontFamily: 'OpenSans',
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.insert_chart_outlined,
                                size: 28,
                                semanticLabel: 'İstatistikler',
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 2,
                                    offset: Offset(1, 1),
                                  ),],
                              ),
                            ],
                          ),
                          Divider(
                            thickness: 2,
                            indent: 20,
                            endIndent: 20,
                            color: Colors.black,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  Icons.directions_walk,
                                  'Toplam Mesafe',
                                  '${totalDistance.toStringAsFixed(2)} km',
                                  Colors.green,
                                ),
                              ),
                              Expanded(
                                child: _buildStatItem(
                                  Icons.nordic_walking_outlined,
                                  'Ortalama Mesafe',
                                  '${averageDistance.toStringAsFixed(2)} km',
                                  Colors.green,
                                ),
                              ),
                            ],
                          ),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildStatItem(
                                Icons.timer,
                                'Toplam Süre',
                                formattedTotalDuration,
                                Colors.blue,
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildStatItem(
                                Icons.fitness_center,
                                'Aktivite Sayısı',
                                '$activityCount',
                                Colors.black,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 10.0),
                  _buildProfileButton(
                    icon: Icons.add,
                    text: 'Yeni Aktivite',
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => NewActivityScreen(),
                      ));
                    },
                  ),
                  SizedBox(height: 8.0),
                  _buildProfileButton(
                    icon: Icons.history,
                    text: 'Aktivite Geçmişim',
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ActivityHistoryScreen(),
                      ));
                    },
                  ),
                  SizedBox(height: 16.0),
                  _buildProfileButton(
                    icon: Icons.logout,
                    text: 'Çıkış Yap',
                    onPressed: () async {
                      try {
                        await FirebaseAuth.instance.signOut();
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      } catch (e) {
                        print("Error signing out: $e");
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(
      IconData icon, String title, String subtitle, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 25),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: basarsoft_color, // Custom color from your constants
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
        ),
        icon: Icon(
          icon,
          size: 24,
          color: Colors.white,
        ),
        label: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3), // Adjust shadow color and opacity
                blurRadius: 2,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

