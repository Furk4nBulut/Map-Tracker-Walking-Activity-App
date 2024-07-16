import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:map_tracker/utils/constants.dart';
import 'activity_detail_screen.dart';
import 'package:map_tracker/screens/partials/appbar.dart'; // Import the CustomAppBar widget

import 'package:flutter/material.dart';
import 'package:map_tracker/model/activity_model.dart';
import 'package:map_tracker/model/user_model.dart';
import 'package:map_tracker/services/local_db_service.dart';
import 'activity_detail_screen.dart';
import 'package:map_tracker/screens/partials/appbar.dart'; // Import the CustomAppBar widget

class ActivityHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Aktivite Geçmişi", automaticallyImplyLeading: true),
      body: FutureBuilder<LocalUser?>(
        future: DatabaseHelper().getCurrentUser(),
        builder: (context, AsyncSnapshot<LocalUser?> userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (userSnapshot.hasError || userSnapshot.data == null) {
            return Center(child: Text('Kullanıcı bilgileri alınamadı.'));
          }

          final user = userSnapshot.data!;

          return FutureBuilder<List<Activity>>(
            future: DatabaseHelper().getUserActivities(user.id!),
            builder: (context, AsyncSnapshot<List<Activity>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Bir hata oluştu: ${snapshot.error.toString()}'));
              }

              final activities = snapshot.data;

              if (activities == null || activities.isEmpty) {
                return Center(child: Text('Aktivite bulunamadı.'));
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 70.0),
                child: ListView.builder(
                  padding: EdgeInsets.all(10.0),
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return Card(
                      color: Colors.white,
                      elevation: 5,
                      margin: EdgeInsets.symmetric(vertical: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
                        title: Row(
                          children: [
                            Icon(Icons.calendar_today, color: Color(0xFF02205C)),
                            SizedBox(width: 10),
                            Text(
                              'Tarih: ${DateFormat('dd MMM yyyy, HH:mm').format(activity.startTime)}',
                              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.directions_walk, color: Colors.green),
                                SizedBox(width: 10),
                                Text(
                                  'Mesafe: ${activity.totalDistance.toStringAsFixed(2)} km',
                                  style: TextStyle(fontSize: 14.0),
                                ),
                              ],
                            ),
                            SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(Icons.timer_outlined, color: Colors.blue),
                                SizedBox(width: 10),
                                Text(
                                  'Süre: ${activity.elapsedTime} saniye',
                                  style: TextStyle(fontSize: 14.0),
                                ),
                              ],
                            ),
                            SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(Icons.speed, color: Colors.deepOrange),
                                SizedBox(width: 10),
                                Text(
                                  'Ortalama Hız: ${activity.averageSpeed.toStringAsFixed(2)} km/s',
                                  style: TextStyle(fontSize: 14.0),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              activity.endTime != null ? 'Durum: Tamamlandı' : 'Durum: Devam Ediyor',
                              style: TextStyle(
                                fontSize: 14.0,
                                color: activity.endTime != null ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, color: basarsoft_color, size: 20.0, semanticLabel: 'Detaylar'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ActivityDetailScreen(activityId: activity.id!.toString()),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

