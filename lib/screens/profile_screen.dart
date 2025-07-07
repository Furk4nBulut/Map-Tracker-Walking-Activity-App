import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:map_tracker/screens/activity_record_screen.dart';
import 'package:map_tracker/screens/new_activity_screen.dart';
import 'package:map_tracker/screens/partials/appbar.dart';
import 'package:map_tracker/utils/constants.dart';
import 'package:map_tracker/model/activity_model.dart';
import 'package:map_tracker/model/user_model.dart';
import 'package:map_tracker/services/local_db_service.dart';
import 'package:intl/intl.dart';
import 'package:map_tracker/services/auth_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:map_tracker/localization/locale_keys.g.dart';
import 'package:map_tracker/widgets/admob_banner.dart';

class ProfilePage extends StatelessWidget {
  final DatabaseHelper dbHelper = DatabaseHelper();

  Future<Map<String, dynamic>> _fetchUserStatistics() async {
    try {
      final LocalUser? localUser = await dbHelper.getCurrentUser();
      final User? firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser != null) {
        return _fetchUserStatisticsFromFirebase(firebaseUser);
      } else if (localUser != null) {
        return _fetchUserStatisticsFromLocal(localUser);
      } else {
        throw LocaleKeys.userInfoNotFound.tr();
      }
    } catch (e) {
      throw LocaleKeys.userStatsError.tr(args: [e.toString()]);
    }
  }

  Future<Map<String, dynamic>> _fetchUserStatisticsFromFirebase(User user) async {
    try {
      final userActivities = FirebaseFirestore.instance
          .collection('user')
          .doc(user.uid)
          .collection('activities');

      final activitiesSnapshot = await userActivities.get();

      double totalDistance = 0.0;
      Duration totalDuration = Duration();
      int activityCount = activitiesSnapshot.size;
      double averageSpeed = 0.0;

      for (var doc in activitiesSnapshot.docs) {
        totalDistance += doc['totalDistance'] ?? 0.0;
        Timestamp startTime = doc['startTime'];
        Timestamp endTime = doc['endTime'];
        totalDuration += endTime.toDate().difference(startTime.toDate());
      }

      double averageDistance = activityCount > 0 ? totalDistance / activityCount : 0.0;
      Duration averageDuration = activityCount > 0 ? totalDuration ~/ activityCount : Duration();

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
      throw LocaleKeys.firebaseStatsError.tr(args: [e.toString()]);
    }
  }

  Future<Map<String, dynamic>> _fetchUserStatisticsFromLocal(LocalUser user) async {
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
  }

  Future<Map<String, String>> _fetchUserProfile() async {
    try {
      final LocalUser? localUser = await dbHelper.getCurrentUser();
      final User? firebaseUser = FirebaseAuth.instance.currentUser;

      if (localUser != null) {
        return {
          'name': localUser.firstName ?? LocaleKeys.unknown.tr(),
          'email': localUser.email ?? LocaleKeys.unknownEmail.tr(),
          'photoURL': '',
        };
      } else if (firebaseUser != null) {
        return {
          'name': firebaseUser.displayName ?? LocaleKeys.unknown.tr(),
          'email': firebaseUser.email ?? LocaleKeys.unknownEmail.tr(),
          'photoURL': firebaseUser.photoURL ?? '',
        };
      } else {
        throw LocaleKeys.userInfoNotFound.tr();
      }
    } catch (e) {
      throw LocaleKeys.userStatsError.tr(args: [e.toString()]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: LocaleKeys.profileTitle.tr(), automaticallyImplyLeading: true),
      body: Column(
        children: [
          AdmobBanner(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: Future.wait([_fetchUserStatistics(), _fetchUserProfile()]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text(LocaleKeys.userStatsError.tr(args: [snapshot.error.toString()])));
                }

                if (!snapshot.hasData) {
                  return Center(child: Text(LocaleKeys.dataLoadFailed.tr()));
                }

                final stats = snapshot.data![0];
                final profile = snapshot.data![1];

                double totalDistance = stats['totalDistance'];
                Duration totalDuration = stats['totalDuration'];
                double averageDistance = stats['averageDistance'];
                Duration averageDuration = stats['averageDuration'];
                int activityCount = stats['activityCount'];
                double averageSpeed = stats['averageSpeed'];

                String formattedTotalDuration = _formatDuration(totalDuration);
                String formattedAverageDuration = _formatDuration(averageDuration);

                return ListView(
                  padding: EdgeInsets.only(bottom: 90.0, top: 5.0),
                  children: [
                    Center(
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
                                backgroundImage: profile['photoURL'] != ''
                                    ? NetworkImage(profile['photoURL']!)
                                    : null,
                                child: profile['photoURL'] == ''
                                    ? const Icon(Icons.person, size: 50)
                                    : null,
                              ),
                            ),
                          ),
                          SizedBox(height: 4.0),
                          Text(
                            profile['name']!,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4.0),
                          Text(
                            profile['email']!,
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
                                          LocaleKeys.totalDistanceLabel.tr(),
                                          '${totalDistance.toStringAsFixed(2)} ${LocaleKeys.kmUnit.tr()}',
                                          Colors.green,
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildStatItem(
                                          Icons.add_road,
                                          LocaleKeys.averageDistanceLabel.tr(),
                                          '${averageDistance.toStringAsFixed(2)} ${LocaleKeys.kmUnit.tr()}',
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
                                          LocaleKeys.totalDurationLabel.tr(),
                                          formattedTotalDuration,
                                          basarsoft_color_light,
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildStatItem(
                                          Icons.timelapse_rounded,
                                          LocaleKeys.averageDurationLabel.tr(),
                                          formattedAverageDuration,
                                          basarsoft_color_light,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.0),
                                  _buildStatItem(
                                    Icons.fitness_center,
                                    LocaleKeys.activityCountLabel.tr(),
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
                            text: LocaleKeys.newActivityButton.tr(),
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => NewActivityScreen(),
                              ));
                            },
                          ),
                          SizedBox(height: 8.0),
                          _buildProfileButton(
                            icon: Icons.history,
                            text: LocaleKeys.activityHistoryButton.tr(),
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => ActivityHistoryScreen(),
                              ));
                            },
                          ),
                          SizedBox(height: 8.0),
                          _buildProfileButton(
                            icon: Icons.sync,
                            text: LocaleKeys.syncDataButton.tr(),
                            onPressed: () async {
                              try {
                                final LocalUser? localUser = await dbHelper.getCurrentUser();
                                if (localUser != null) {
                                  await AuthService().syncUserActivities(context, localUser);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(LocaleKeys.syncSuccess.tr())),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(LocaleKeys.userStatsError.tr(args: [e.toString()]))),
                                );
                              }
                            },
                          ),
                          SizedBox(height: 8.0),
                          _buildProfileButton(
                            icon: Icons.logout,
                            text: LocaleKeys.logoutButton.tr(),
                            onPressed: () async {
                              try {
                                await FirebaseAuth.instance.signOut();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(LocaleKeys.logoutSuccess.tr())),
                                );
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(LocaleKeys.userStatsError.tr(args: [e.toString()]))),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: null,
    );
  }

  String _formatDuration(Duration duration) {
    return "${duration.inHours} ${LocaleKeys.hourUnit.tr()} ${duration.inMinutes.remainder(60)} ${LocaleKeys.minuteUnitShort.tr()} ${duration.inSeconds.remainder(60)} ${LocaleKeys.secondUnitShort.tr()}";
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
    return Padding(
      padding: const EdgeInsets.only(left: 10.0, right: 10.0),
      child: SizedBox(
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
      ),
    );
  }
}