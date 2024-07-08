import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'activity_detail_screen.dart';
import 'package:map_tracker/screens/partials/appbar.dart'; // Import the CustomAppBar widget

class ActivityHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Handle appropriately if the user is not logged in (e.g., show login screen)
      return Scaffold(
        appBar: CustomAppBar(title: "Aktivite Geçmişi", automaticallyImplyLeading: true),
        body: Center(
          child: Text('Kullanıcı girişi gereklidir.'),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(title: "Aktivite Geçmişi", automaticallyImplyLeading: true),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('user')
            .doc(user.uid)
            .collection('activities')
            .orderBy('startTime', descending: true) // Sort by startTime descending
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

          return ListView(
            padding: EdgeInsets.all(10.0),
            children: snapshot.data!.docs.map((doc) {
              if (!doc.exists || !doc.data().containsKey('startTime')) {
                return SizedBox(); // Return an empty widget if document doesn't exist or startTime field is missing
              }

              Timestamp startTimeStamp = doc['startTime'];
              DateTime startTime = startTimeStamp.toDate();
              double totalDistance = doc['totalDistance'] ?? 0.0;
              bool isCompleted = doc['endTime'] != null;
              // Calculate average speed
              num averageSpeed = totalDistance / (doc['elapsedTime'] / 3600);
              // Format date
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
                      Icon(Icons.calendar_today, color: Colors.blue),
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
                          Icon(Icons.directions_walk, color: Colors.blue),
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
                  trailing: Icon(Icons.arrow_forward_ios, color: Colors.blue, size: 20.0, semanticLabel: 'Detaylar',),
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
            }).toList(),
          );
        },
      ),
    );
  }
}
