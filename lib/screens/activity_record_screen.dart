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
import 'package:easy_localization/easy_localization.dart';
import 'package:map_tracker/localization/locale_keys.g.dart';
import 'package:map_tracker/widgets/admob_banner.dart';
import 'package:map_tracker/widgets/admob_interstitial.dart';

class ActivityHistoryScreen extends StatelessWidget {
  final AdmobInterstitial _admobInterstitial = AdmobInterstitial();

  void showInterstitialAdOnComplete(BuildContext context) {
    _admobInterstitial.loadAd(onLoaded: () {
      _admobInterstitial.showAd();
    });
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: CustomAppBar(title: LocaleKeys.activityHistoryTitle.tr(), automaticallyImplyLeading: true),
      body: Column(
        children: [
          AdmobBanner(),
          Expanded(
            child: firebaseUser == null
                ? Center(child: Text(LocaleKeys.loginRequired.tr()))
                : _fetchActivitiesFromFirestore(firebaseUser.uid),
          ),
        ],
      ),
      bottomNavigationBar: null,
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
          return Center(child: Text(LocaleKeys.errorOccurred.tr(args: [snapshot.error.toString()])));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text(LocaleKeys.noActivitiesFound.tr()));
        }

        return buildFirestoreActivityList(snapshot.data!.docs);
      },
    );
  }

  Widget buildFirestoreActivityList(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 70.0),
      child: Column(
        children: [
          Expanded(
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
                          '${LocaleKeys.dateLabel.tr()}: $formattedDate',
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
                              '${LocaleKeys.distanceLabel.tr()}: ${totalDistance.toStringAsFixed(2)} ${LocaleKeys.kmUnit.tr()}',
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
                              '${LocaleKeys.durationLabel.tr()}: ${doc['elapsedTime']} ${LocaleKeys.secondUnit.tr()}',
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
                              '${LocaleKeys.averageSpeedLabel.tr()}: ${averageSpeed.toStringAsFixed(2)} ${LocaleKeys.kmPerHourUnit.tr()}',
                              style: TextStyle(fontSize: 14.0),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          isCompleted ? LocaleKeys.statusCompleted.tr() : LocaleKeys.statusOngoing.tr(),
                          style: TextStyle(
                            fontSize: 14.0,
                            color: isCompleted ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, color: basarsoft_color, size: 20.0, semanticLabel: LocaleKeys.detailsLabel.tr()),
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
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget buildActivityList(List<Activity> activities, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 70.0),
      child: Column(
        children: [
          Expanded(
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
                          '${LocaleKeys.dateLabel.tr()}: ${DateFormat('dd MMM yyyy, HH:mm').format(activity.startTime)}',
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
                              '${LocaleKeys.distanceLabel.tr()}: ${activity.totalDistance.toStringAsFixed(2)} ${LocaleKeys.kmUnit.tr()}',
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
                              '${LocaleKeys.durationLabel.tr()}: ${activity.elapsedTime} ${LocaleKeys.secondUnit.tr()}',
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
                              '${LocaleKeys.averageSpeedLabel.tr()}: ${activity.averageSpeed.toStringAsFixed(2)} ${LocaleKeys.kmPerHourUnit.tr()}',
                              style: TextStyle(fontSize: 14.0),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          activity.endTime != null ? LocaleKeys.statusCompleted.tr() : LocaleKeys.statusOngoing.tr(),
                          style: TextStyle(
                            fontSize: 14.0,
                            color: activity.endTime != null ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, color: basarsoft_color, size: 20.0, semanticLabel: LocaleKeys.detailsLabel.tr()),
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
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}