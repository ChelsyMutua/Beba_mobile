import 'package:flutter/material.dart';

class FormAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FormAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 60, // Increase the height of the AppBar
      automaticallyImplyLeading: false, // Disable default leading widget
      title: Align(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: SizedBox(
            height: 35, // Adjust this value to control logo height
            child: Image.asset(
              'assets/images/BebaPass_hr.png',
              // fit: BoxFit.contain, // This ensures the image scales properly
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60.0); // Match toolbarHeight
}