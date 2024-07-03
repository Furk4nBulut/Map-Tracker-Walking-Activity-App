import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatelessWidget {
  final User user;

  ProfilePage({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profil"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text("Kullanıcı Adı: ${user.displayName ?? 'Bilinmiyor'}"),
              subtitle: Text("Email: ${user.email}"),
              leading: CircleAvatar(
                backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                child: user.photoURL == null ? const Icon(Icons.person) : null,
              ),
            ),
            const SizedBox(height: 16.0),

          ],
        ),
      ),
    );
  }
}
