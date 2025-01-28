import 'package:beba_mobile/screens/scan_ticket.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFA07A), // Light orange
            Color(0xFF00DCDC), // Aqua green
            Color(0xFF002B36), // Dark teal
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CustomAppBar(),
            Expanded(
              child: LayoutBuilder(
                // Add LayoutBuilder for constraints
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  final screenHeight = constraints.maxHeight;

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Center Circle (Main Logo)
                      Positioned(
                        child: Container(
                          width: screenWidth * 0.3, // 30% of screen width
                          height: screenWidth * 0.3,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              "assets/images/center logo.png",
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),

                      // Top Left Circle (View Events)
                      Positioned(
                        top: screenHeight * 0.35, // 38% from top
                        left: screenWidth * 0.1, // 10% from left
                        child: GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(context, "/view_events"),
                          child: ResponsiveCircle(
                            size: screenWidth * 0.28, // 25% of screen width
                            imagePath: "assets/images/Create event.png",
                          ),
                        ),
                      ),

                      // Top Right Circle (Create Event)
                      Positioned(
                        top: screenHeight * 0.35, // 38% from top
                        right: screenWidth * 0.1, // 10% from right
                        child: GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(context, "/view_events"),
                          child: ResponsiveCircle(
                            size: screenWidth * 0.28,
                            imagePath: "assets/images/viewEvents.png",
                          ),
                        ),
                      ),

                      // Bottom Circle (Tickets/Scan)
                      Positioned(
                        bottom: screenHeight * 0.25, // 25% from bottom
                        child: GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const ScanTicketScreen(),
                            );
                          },
                          child: ResponsiveCircle(
                            size: screenWidth * 0.28,
                            imagePath: "assets/images/scan event.png",
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
          top: 60, left: 16, right: 16), // Adjust for status bar
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Profile Section
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage:
                    AssetImage("assets/images/B_logo.png"), // Your image
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "TedMbg",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    "#dev_life",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Bebapass hr logo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 6),
            decoration: BoxDecoration(
              color: Colors
                  .transparent, // Remove background color if logo has its own
              borderRadius: BorderRadius.circular(20),
            ),
            child: Image.asset(
              "assets/images/BebaPass_hr.png", // Ensure the image is in assets folder
              height: 40, // Adjust based on logo size
            ),
          )
        ],
      ),
    );
  }
}

class CircleIconWidget extends StatelessWidget {
  final String imagePath;

  const CircleIconWidget({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.orange[300], // Background similar to the design
      ),
      child: Center(
        child: Image.asset(
          imagePath,
          width: 50,
        ),
      ),
    );
  }
}

class ResponsiveCircle extends StatelessWidget {
  final double size;
  final String imagePath;

  const ResponsiveCircle({
    super.key,
    required this.size,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
