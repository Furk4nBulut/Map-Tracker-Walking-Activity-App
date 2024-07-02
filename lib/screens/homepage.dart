import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:map_tracker/services/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final User? user = ModalRoute.of(context)?.settings.arguments as User?;

    return Scaffold(
      appBar: AppBar(
        title: Text("Map Tracker App"),
        centerTitle: true,
        automaticallyImplyLeading: true, // Geri butonunu göster
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isCurrent);
          },
        ),

        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              await AuthService().signOut();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (user != null)
            ListTile(
              title: Text("Kullanıcı Adı: ${user.displayName ?? 'Bilinmiyor'}"),
              subtitle: Text("Email: ${user.email}"),
              leading: CircleAvatar(
                backgroundImage: NetworkImage(user.photoURL ?? ""),
              ),
            ),
          if (user == null)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Giriş Yapılmadı"),
            ),
          Expanded(
            child: Center(
              child: Text(
                "Uygulamanın ana içeriği burada olacak",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
