import 'package:beba_mobile/screens/loading_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../screens/home/home.dart'; // Import your HomeScreen

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        child: Stack(
          children: [
            // Top Center Image (Covers half of the screen)
            Positioned(
              top: -180,
              left: 0,
              right: 0,
              child: Image.asset(
                "assets/images/top splash.png",
                width: screenWidth,
                height: screenHeight * 0.7,
                fit: BoxFit.fitHeight, // Ensures it covers the area
              ),
            ),

            // Bottom Image (Almost half of the screen)
            Positioned(
              bottom: -45,
              left: 0,
              right: 0,
              child: Image.asset(
                "assets/images/bottom splash.png",
                width: screenWidth,
                height: screenHeight * 0.47,
                fit: BoxFit.cover,
              ),
            ),

            // Center Left Image
            Positioned(
              left: screenWidth * -0.45, // Adjust positioning
              top: screenHeight * 0.305, // Adjust to center-left
              child: Image.asset(
                "assets/images/sidesplash.png",
                width: screenWidth * 0.65, // Adjust size
                fit: BoxFit.contain,
              ),
            ),

            // Center Right Image (Overlays bottom image)
           Positioned(
  right: screenWidth * -0.07, // Adjust position
  top: screenHeight * 0.53, // Slightly below center
  child: GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoadingScreen()),
      );
    },
    child: Image.asset(
      "assets/images/start splash.png", // Ensure filename is correct
      width: screenWidth * 0.65,
      fit: BoxFit.contain,
    ),
  ),
),


            // Splash screen delay before navigating to home
            Positioned.fill(
              child: Center(
                  // child: FutureBuilder(
                  //   future: Future.delayed(const Duration(seconds: 3)), // 3-second delay
                  //   builder: (context, snapshot) {
                  //     if (snapshot.connectionState == ConnectionState.done) {
                  //       WidgetsBinding.instance.addPostFrameCallback((_) {
                  //         Navigator.pushReplacement(
                  //           context,
                  //           MaterialPageRoute(builder: (context) => const HomeScreen()),
                  //         );
                  //       });
                  //     }
                  //     return const SizedBox(); // Keeps UI clean
                  //   },
                  // ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
