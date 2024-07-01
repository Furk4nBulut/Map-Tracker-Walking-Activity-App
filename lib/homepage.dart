import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>{
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text("Map Tracker App"),
        centerTitle: true,
        automaticallyImplyLeading: false, // Geri tuşunu kaldırır
      ),
         body: Center(
      child: Text("Map will be here!",
      style: TextStyle(
        fontSize: 30,
      color: Colors.black)
    ),
    ),
    );
  }

}