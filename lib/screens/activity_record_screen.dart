import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:map_tracker/utils/constants.dart';
import 'activity_detail_screen.dart';
import 'package:map_tracker/screens/partials/appbar.dart';
import 'package:map_tracker/model/activity_model.dart';
import 'package:map_tracker/model/user_model.dart';
import 'package:map_tracker/services/local_db_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Aktivite Geçmişi", automaticallyImplyLeading: true),
      body: FutureBuilder<LocalUser?>(
        future: DatabaseHelper().getCurrentUser(),
        builder: (context, AsyncSnapshot<LocalUser?> localUserSnapshot) {
          if (localUserSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (localUserSnapshot.hasError) {
            return Center(child: Text('Bir hata oluştu: ${localUserSnapshot.error}'));
          }

          if (localUserSnapshot.data != null) {
            final localUser = localUserSnapshot.data!;
            return FutureBuilder<List<Activity>>(
              future: DatabaseHelper().getUserActivities(localUser.id!),
              builder: (context, AsyncSnapshot<List<Activity>> activitiesSnapshot) {
                if (activitiesSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (activitiesSnapshot.hasError) {
                  return Center(child: Text('Bir hata oluştu: ${activitiesSnapshot.error}'));
                }

                final activities = activitiesSnapshot.data;

                if (activities == null || activities.isEmpty) {
                  return _fetchActivitiesFromFirestore(localUser.id!.toString());
                }

                return buildActivityList(activities, context);
              },
            );
          } else {
            final User? firebaseUser = FirebaseAuth.instance.currentUser;

            if (firebaseUser == null) {
              return Scaffold(
                appBar: CustomAppBar(title: "Aktivite Geçmişi", automaticallyImplyLeading: true),
                body: Center(child: Text('Kullanıcı girişi gereklidir.')),
              );
            }

            return _fetchActivitiesFromFirestore(firebaseUser.uid);
          }
        },
      ),
    );
  }

  Widget _fetchActivitiesFromFirestore(String userId) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('user')
          .doc(userId)
          .collection('activities')
          .orderBy('startTime', descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Bir hata oluştu: ${snapshot.error.toString()}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('Aktivite bulunamadı.'));
        }

        return buildFirestoreActivityList(snapshot.data!.docs);
      },
    );
  }

  Widget buildFirestoreActivityList(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 70.0),
      child: ListView.builder(
        padding: EdgeInsets.all(10.0),
        itemCount: docs.length,
        itemBuilder: (context, index) {
          var doc = docs[index];

          if (!doc.exists || !doc.data().containsKey('startTime')) {
            return SizedBox();
          }

          Timestamp startTimeStamp = doc['startTime'];
          DateTime startTime = startTimeStamp.toDate();
          double totalDistance = doc['totalDistance'] ?? 0.0;
          bool isCompleted = doc['endTime'] != null;
          num averageSpeed = totalDistance / (doc['elapsedTime'] / 3600);
          String formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(startTime);

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
                    'Tarih: $formattedDate',
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
                        'Mesafe: ${totalDistance.toStringAsFixed(2)} km',
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
                        'Süre: ${doc['elapsedTime']} saniye',
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
                        'Ortalama Hız: ${averageSpeed.toStringAsFixed(2)} km/s',
                        style: TextStyle(fontSize: 14.0),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    isCompleted ? 'Durum: Tamamlandı' : 'Durum: Devam Ediyor',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: isCompleted ? Colors.green : Colors.orange,
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
                    builder: (context) => ActivityDetailScreen(activityId: doc.id),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget buildActivityList(List<Activity> activities, BuildContext context) {
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
                    builder: (context) => ActivityDetailScreen(activityId: activity.id!),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}