import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:map_tracker/homepage.dart';

void main(){
  runApp(MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp>{

  @override
  void initState(){
    super.initState();
    Future.delayed(Duration(seconds: 3), (){
      Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
    });
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/Furkan_Bulut.jpg"),
            fit: BoxFit.cover
          )
        ),
      ),
    );
  }

}