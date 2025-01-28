import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  colorScheme: const ColorScheme.light(
    primary: Colors.white,         // Primary color (white theme)
    onPrimary: Colors.black,       // Text/icons on primary color
    secondary: Colors.white,       // Secondary color
    onSecondary: Colors.black,     // Text/icons on secondary color
    background: Colors.white,      // Background color
    onBackground: Colors.black,    // Text/icons on background
    surface: Colors.white,         // Surface color
    onSurface: Colors.black,       // Text/icons on surfaces
  ),
  scaffoldBackgroundColor: Colors.white, // Set full app background to white
  useMaterial3: true,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,      // White AppBar
    foregroundColor: Colors.black,      // Black icons and text
    elevation: 0,                        // Removes AppBar shadow
    surfaceTintColor: Colors.transparent // Fixes cream tint issue
  ),
);
