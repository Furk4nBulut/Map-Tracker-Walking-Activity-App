import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:map_tracker/screens/activity_record_screen.dart';
import 'package:map_tracker/screens/new_activity_screen.dart';
import 'package:map_tracker/screens/partials/appbar.dart';
import 'package:map_tracker/utils/constants.dart';
import 'package:map_tracker/model/activity_model.dart';
import 'package:map_tracker/model/user_model.dart';
import 'package:map_tracker/services/local_db_service.dart'; // DatabaseHelper kullanılacak
import 'package:intl/intl.dart'; // Tarih biçimlendirme için

class ProfilePage extends StatelessWidget {
  final DatabaseHelper dbHelper = DatabaseHelper();

  Future<Map<String, dynamic>> _fetchUserStatistics() async {
    try {
      final LocalUser? user = await dbHelper.getCurrentUser();
      if (user == null) {
        throw 'Kullanıcı oturumu açmamış.';
      }

      List<Activity> userActivities = await dbHelper.getUserActivities(user.id!);

      double totalDistance = 0.0;
      Duration totalDuration = Duration();
      int activityCount = userActivities.length;
      double averageSpeed = 0.0;

      for (var activity in userActivities) {
        totalDistance += activity.totalDistance ?? 0.0;
        if (activity.startTime != null && activity.endTime != null) {
          totalDuration += activity.endTime!.difference(activity.startTime!);
        }
      }

      double averageDistance = activityCount > 0 ? totalDistance / activityCount : 0.0;
      Duration averageDuration = activityCount > 0 ? totalDuration ~/ activityCount : Duration();

      // Calculate average speed
      if (totalDuration.inHours > 0) {
        averageSpeed = totalDistance / totalDuration.inHours;
      }

      return {
        'totalDistance': totalDistance,
        'totalDuration': totalDuration,
        'averageDistance': averageDistance,
        'averageDuration': averageDuration,
        'activityCount': activityCount,
        'averageSpeed': averageSpeed,
      };
    } catch (e) {
      throw ('Kullanıcı istatistikleri alınırken hata oluştu: $e');
    }
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
            return Center(child: Text('Bir hata oluştu: ${snapshot.error.toString()}'));
          }

          if (!snapshot.hasData) {
            return Center(child: Text('Veriler yüklenemedi.'));
          }

          Map<String, dynamic> stats = snapshot.data!;
          double totalDistance = stats['totalDistance'];
          Duration totalDuration = stats['totalDuration'];
          double averageDistance = stats['averageDistance'];
          Duration averageDuration = stats['averageDuration'];
          int activityCount = stats['activityCount'];
          double averageSpeed = stats['averageSpeed'];

          String formattedTotalDuration = _formatDuration(totalDuration);
          String formattedAverageDuration = _formatDuration(averageDuration);

          return SingleChildScrollView(
            padding: EdgeInsets.all(8.0),
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
                      padding: EdgeInsets.all(6),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: FirebaseAuth.instance.currentUser?.photoURL != null
                            ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!)
                            : null,
                        child: FirebaseAuth.instance.currentUser?.photoURL == null
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                    ),
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    FirebaseAuth.instance.currentUser?.displayName ?? 'Bilinmiyor',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    FirebaseAuth.instance.currentUser?.email ?? 'Email bilinmiyor',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Card(
                    color: Colors.white,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                    ),
                    shadowColor: basarsoft_color,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
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
                                  Icons.add_road,
                                  'Ortalama Mesafe',
                                  '${averageDistance.toStringAsFixed(2)} km',
                                  Colors.green,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  Icons.timer_outlined,
                                  'Toplam Süre',
                                  formattedTotalDuration,
                                  basarsoft_color_light,
                                ),
                              ),
                              Expanded(
                                child: _buildStatItem(
                                  Icons.timelapse_rounded,
                                  'Ortalama Süre',
                                  formattedAverageDuration,
                                  basarsoft_color_light,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.0),
                          _buildStatItem(
                            Icons.fitness_center,
                            'Aktivite Sayısı',
                            '$activityCount',
                            Colors.white,
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
                        print("Çıkış yaparken hata oluştu: $e");
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

  String _formatDuration(Duration duration) {
    return "${duration.inHours} saat ${duration.inMinutes.remainder(60)} dk ${duration.inSeconds.remainder(60)} sn";
  }

  Widget _buildStatItem(
      IconData icon, String title, String subtitle, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: basarsoft_color,
              border: Border.all(color: basarsoft_color_light, width: 2),
            ),
            padding: EdgeInsets.all(8),
            child: Icon(icon, color: iconColor, size: 25),
          ),
          SizedBox(width: 5),
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
              SizedBox(height: 4),
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
          backgroundColor: basarsoft_color,
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
                color: Colors.black.withOpacity(0.3),
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

