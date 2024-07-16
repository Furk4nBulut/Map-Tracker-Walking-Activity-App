import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:map_tracker/model/activity_model.dart';
import 'package:map_tracker/services/local_db_service.dart';
import 'package:map_tracker/model/user_model.dart';
import 'package:map_tracker/services/local_db_service.dart';
import 'package:map_tracker/screens/partials/appbar.dart'; // Adjust this import as per your project structure
import 'package:map_tracker/utils/constants.dart'; // Adjust this import as per your project structure

class StatisticPage extends StatelessWidget {
  final DatabaseHelper dbHelper = DatabaseHelper();

  Future<Map<String, dynamic>> _getUserStatistics() async {
    try {
      LocalUser? currentUser = await dbHelper.getCurrentUser();
      if (currentUser == null) {
        throw 'Kullanıcı oturumu açmamış.';
      }

      List<Activity> userActivities = await dbHelper.getUserActivities(currentUser.id!);

      double totalDistance = 0.0;
      Duration totalDuration = Duration();
      int activityCount = userActivities.length;

      for (var activity in userActivities) {
        totalDistance += activity.totalDistance ?? 0.0;

        if (activity.startTime != null && activity.endTime != null) {
          totalDuration += activity.endTime!.difference(activity.startTime!);
        }
      }

      double averageDistance = activityCount > 0 ? totalDistance / activityCount : 0.0;
      Duration averageDuration = activityCount > 0 ? totalDuration ~/ activityCount : Duration();

      // Calculate average speed
      double averageSpeed = totalDuration.inHours > 0 ? totalDistance / totalDuration.inHours : 0.0;

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
      appBar: CustomAppBar(
        title: 'İstatistikler', // Adjust title as per your preference
        automaticallyImplyLeading: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getUserStatistics(),
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
          String formattedAverageSpeed = averageSpeed.toStringAsFixed(2); // Format average speed to show two decimal places

          return SingleChildScrollView(
            padding: EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildStatItem(
                  icon: Icons.directions_walk,
                  title: 'Toplam Mesafe',
                  subtitle: '${totalDistance.toStringAsFixed(2)} km',
                  iconColor: Colors.green,
                ),
                _buildStatItem(
                  icon: Icons.add_road,
                  title: 'Ortalama Mesafe',
                  subtitle: '${averageDistance.toStringAsFixed(2)} km',
                  iconColor: Colors.green,
                ),
                _buildStatItem(
                  icon: Icons.timer_outlined,
                  title: 'Toplam Süre',
                  subtitle: formattedTotalDuration,
                  iconColor: basarsoft_color_light,
                ),
                _buildStatItem(
                  icon: Icons.timelapse_rounded,
                  title: 'Ortalama Süre',
                  subtitle: formattedAverageDuration,
                  iconColor: Colors.blueAccent,
                ),
                _buildStatItem(
                  icon: Icons.speed_outlined,
                  title: 'Ortalama Hız',
                  subtitle: '${formattedAverageSpeed} km/saat',
                  iconColor: Colors.red,
                ),
                _buildStatItem(
                  icon: Icons.fitness_center,
                  title: 'Aktivite Sayısı',
                  subtitle: '$activityCount',
                  iconColor: Colors.white,
                ),
                SizedBox(height: 70.0), // Add space at the bottom
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    return '${duration.inHours} saat ${duration.inMinutes.remainder(60)} dakika ${duration.inSeconds.remainder(60)} saniye';
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    return Card(
      elevation: 30, // Increase elevation for stronger shadow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: Colors.white,
      shadowColor: basarsoft_color,
      margin: EdgeInsets.only(bottom: 20.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: basarsoft_color,
                border: Border.all(color: basarsoft_color_light, width: 3), // White border around the circle
              ),
              padding: EdgeInsets.all(12),
              child: Icon(icon, color: iconColor, size: 40),
            ),
            SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: basarsoft_color, // Match with basarsoft_color for title
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.black87, // Darker text color for subtitle
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
