import 'package:flutter/material.dart';
import 'package:map_tracker/services/auth_service.dart';
import 'package:map_tracker/screens/partials/appbar.dart';
import 'package:map_tracker/screens/homepage.dart';
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool automaticallyImplyLeading;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.automaticallyImplyLeading = true, // Default to false
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w600,
        shadows: <Shadow>[
          Shadow(
            offset: Offset(2.0, 2.0),
            blurRadius: 3.0,
            color: Colors.black,
          ),
        ],

      ),
      backgroundColor: Colors.blue,



      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: automaticallyImplyLeading
          ? IconButton(
        icon: const Icon(Icons.home_outlined,
          shadows: [
            Shadow(
              offset: Offset(2.0, 2.0),
              blurRadius: 3.0,
              color: Colors.black,
            ),
          ],),
        color: Colors.white,
        onPressed: () {
          //home page back button direkt yönlednrme home page e
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        },
      )
          : null,




      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.exit_to_app,
          shadows: [
            Shadow(
              offset: Offset(2.0, 2.0),
              blurRadius: 3.0,
              color: Colors.black,
            ),
          ],),
          color: Colors.white,
          onPressed: () async {
            await AuthService().signOut();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
