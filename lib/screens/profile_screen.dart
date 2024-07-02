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
                backgroundImage: NetworkImage(user.photoURL ?? ""),
              ),
            ),
            const SizedBox(height: 16.0),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Genel Profil ve Spor Durumu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8.0),
                    Text("Toplam Yapılan Mesafe: 120 km"),
                    Text("Toplam Süre: 10 saat"),
                    Text("Aktivite Sayısı: 25"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
