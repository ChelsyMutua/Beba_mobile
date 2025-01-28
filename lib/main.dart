import 'package:beba_mobile/screens/scan_ticket.dart';
import 'package:beba_mobile/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'theme/theme.dart'; // Import theme
import './screens/home/home.dart'; // Import HomeScreen
import './screens/view_events.dart'; // Import ViewEventsScreen

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
      initialRoute: "/", // Set initial route
      routes: {
        "/": (context) => const SplashScreen(),
        "/view_events": (context) => const ViewEventsScreen(), // Register view events page
        "/scan_ticket": (context) => const ScanTicketScreen() // redirect to scan tickets.
      },
    );
  }
}
