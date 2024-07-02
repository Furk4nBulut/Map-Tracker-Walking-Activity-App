import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final User? user = ModalRoute.of(context)?.settings.arguments as User?;

    return Scaffold(
      appBar: AppBar(
        title: Text("Map Tracker App"),
        centerTitle: true,
        automaticallyImplyLeading: true, // Geri tuşunu kaldırır
      ),
      body: Center(
        child: user != null
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Map will be here!",
              style: TextStyle(fontSize: 30, color: Colors.black),
            ),
            SizedBox(height: 20),
            Text(
              "User Email: ${user.email ?? 'Not available'}",
              style: TextStyle(fontSize: 20, color: Colors.black),
            ),
            Text(
              "User UID: ${user.uid}",
              style: TextStyle(fontSize: 20, color: Colors.black),
            ),
          ],
        )
            : Text(
          "No user information available.",
          style: TextStyle(fontSize: 20, color: Colors.black),
        ),
      ),
    );
  }
}
