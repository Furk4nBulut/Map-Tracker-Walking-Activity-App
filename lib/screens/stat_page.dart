import 'package:flutter/material.dart';
import 'package:map_tracker/screens/partials/appbar.dart';

class StatisticPage extends StatelessWidget {
  const StatisticPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'İstatistikler',
        automaticallyImplyLeading: true,
      ),
      body: Center(
        child: Text('İstatistikler'),


      ),
    );
  }
}