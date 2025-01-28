import 'package:flutter/material.dart';
import 'theme/theme.dart'; // Import theme
import './screens/home/home.dart'; // Import HomeScreen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: appTheme, // Apply the custom theme
      home: const HomeScreen(), // Use HomeScreen
    );
  }
}
