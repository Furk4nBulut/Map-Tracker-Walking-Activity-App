import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:map_tracker/screens/partials/appbar.dart'; // Adjust this import as per your project structure
import 'package:map_tracker/utils/constants.dart'; // Adjust this import as per your project structure

class StatisticPage extends StatelessWidget {
  final User user;

  const StatisticPage({Key? key, required this.user}) : super(key: key);

  Future<Map<String, dynamic>> _fetchUserStatistics() async {
    try {
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

        // Convert Timestamp to DateTime
        DateTime startDate = startTime.toDate();
        DateTime endDate = endTime.toDate();

        // Calculate duration
        totalDuration += endDate.difference(startDate);
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
      throw ('Error fetching user statistics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'İstatistikler', // Adjust title as per your preference
        automaticallyImplyLeading: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
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
                    ],
                  ),
                );
              },
            ),
          ),
        ],
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
      margin: EdgeInsets.symmetric(vertical: 15),
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
