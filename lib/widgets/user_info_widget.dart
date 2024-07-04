import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserInfoWidget extends StatelessWidget {
  final User? user;

  const UserInfoWidget({Key? key, this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (user != null)
              Column(
                children: [
                  ListTile(
                    title: Text("Kullanıcı Adı: ${user!.displayName ?? 'Bilinmiyor'}"),
                    subtitle: Text("Email: ${user!.email ?? 'Bilinmiyor'}"),
                    leading: CircleAvatar(
                      backgroundImage: user!.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                      child: user!.photoURL == null ? const Icon(Icons.person) : null,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                ],
              )
            else
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Giriş Yapılmadı"),
              ),
          ],
        ),
      ),
    );
  }
}
