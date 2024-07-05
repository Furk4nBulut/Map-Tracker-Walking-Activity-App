import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'activity_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActivityHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // If no user is logged in, handle appropriately (e.g., show login screen)
      return Scaffold(
        appBar: AppBar(
          title: Text('Aktivite Geçmişi'),
        ),
        body: Center(
          child: Text('Kullanıcı girişi gereklidir.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Aktivite Geçmişi'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('user')
            .doc(user.uid)
            .collection('activities')
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
            children: snapshot.data!.docs.map((doc) {
              if (!doc.exists || !doc.data().containsKey('startTime')) {
                return SizedBox(); // Belge yoksa veya startTime alanı yoksa boş bir widget döndür
              }

              Timestamp startTimeStamp = doc['startTime'];
              DateTime startTime = startTimeStamp.toDate();
              double totalDistance = doc['totalDistance'] ?? 0.0;
              bool isCompleted = doc['endTime'] != null;

              return ListTile(
                title: Text('Tarih: ${startTime.toString()}'),
                subtitle: Text('Mesafe: ${totalDistance.toStringAsFixed(2)} km'),
                trailing: Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ActivityDetailScreen(activityId: doc.id),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
