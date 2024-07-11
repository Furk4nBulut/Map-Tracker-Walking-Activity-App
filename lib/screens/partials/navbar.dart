import 'package:flutter/material.dart';
import 'package:map_tracker/utils/constants.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const BottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: basarsoft_color,
      shape: CircularNotchedRectangle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _buildAnimatedIconButton(Icons.home_outlined, 0),
          _buildAnimatedIconButton(Icons.bar_chart_outlined, 1),

          FloatingActionButton(
            backgroundColor: basarsoft_color_light,
            onPressed: () => onItemTapped(2),
            child: Icon(
              Icons.add_outlined,
              color: Colors.white,
              size: 35,
              shadows: [
                BoxShadow(
                  color: basarsoft_color,
                  blurRadius: 20,
                  spreadRadius: 1,
                  offset: Offset(0, 0),
                ),
              ],
            ),
          ),
          _buildAnimatedIconButton(Icons.history_outlined, 3),
          _buildAnimatedIconButton(Icons.person_outline, 4),
        ],
      ),
    );
  }

  Widget _buildAnimatedIconButton(IconData icon, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 10),
      padding: EdgeInsets.all(0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: selectedIndex == index ? basarsoft_color_light.withOpacity(0.1) : Colors.transparent,
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: selectedIndex == index ? Colors.white : Colors.white,
        ),
        onPressed: () => onItemTapped(index),
      ),
    );
  }
}
