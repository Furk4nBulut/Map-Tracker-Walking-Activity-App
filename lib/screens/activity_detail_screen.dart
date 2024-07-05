import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActivityDetailScreen extends StatelessWidget {
  final String activityId;

  ActivityDetailScreen({required this.activityId});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // If no user is logged in, handle appropriately (e.g., show login screen)
      return Scaffold(
        appBar: AppBar(
          title: Text('Aktivite Detayı'),
        ),
        body: Center(
          child: Text('Kullanıcı girişi gereklidir.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Aktivite Detayı'),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('user')
            .doc(user.uid)
            .collection('activities')
            .doc(activityId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Bir hata oluştu: ${snapshot.error.toString()}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Aktivite bulunamadı.'));
          }

          var data = snapshot.data!.data()!;
          Timestamp startTimeStamp = data['startTime'];
          DateTime startTime = startTimeStamp.toDate();
          Timestamp? endTimeStamp = data['endTime'];
          DateTime? endTime = endTimeStamp?.toDate();
          double totalDistance = data['totalDistance'] ?? 0.0;
          int elapsedTime = data['elapsedTime'] ?? 0;
          double averageSpeed = (totalDistance > 0 && elapsedTime > 0)
              ? totalDistance / (elapsedTime / 3600)
              : 0;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Başlangıç Zamanı: ${startTime.toString()}'),
                Text('Bitiş Zamanı: ${endTime != null ? endTime.toString() : 'Devam Ediyor'}'),
                Text('Toplam Mesafe: ${totalDistance.toStringAsFixed(2)} km'),
                Text('Geçen Süre: ${elapsedTime} saniye'),
                Text('Ortalama Hız: ${averageSpeed.toStringAsFixed(2)} km/s'),

              ],
            ),
          );
        },
      ),
    );
  }
}