import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:map_tracker/screens/homepage.dart';
import 'package:map_tracker/screens/partials/appbar.dart'; // Import the BottomNavBar widget
import 'package:map_tracker/utils/constants.dart';


class ProfilePage extends StatelessWidget {
  final User user;

  const ProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Profil", automaticallyImplyLeading: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                child: user.photoURL == null ? const Icon(Icons.person, size: 50) : null,
              ),
              const SizedBox(height: 16.0),
              Text(
                user.displayName ?? 'Bilinmiyor',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                user.email ?? 'Email bilinmiyor',
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  } catch (e) {
                    print("Error signing out: $e");
                  }
                },
                child: const Text('Çıkış Yap', style: TextStyle(fontSize: 18, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: basarsoft_color,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}
