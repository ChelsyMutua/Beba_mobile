import 'package:flutter/material.dart';
import 'dart:async';
import 'home/home.dart'; // Import the HomeScreen

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _animation;
  String imagePath = "assets/images/loading.png"; // Initial image

  @override
  void initState() {
    super.initState();

    // Animation Controller (Runs for 3 seconds)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Animate Gradient Moving from Bottom to Top
    _animation = AlignmentTween(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ).animate(_controller);

    // Start Animation
    _controller.forward();

    // Change image to "Done" after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        imagePath = "assets/images/done.png"; // Change to done image
      });
    });

    // Navigate to Home after 5 seconds
    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: _animation.value,
                end: Alignment.topCenter,
                colors: [
                  const Color(0xFF00DCDC), // Aqua Green
                  const Color(0xFFFFA07A), // Light Orange
                  const Color(0xFF03646B)
                ],
              ),
            ),
            child: Center(
              child: Image.asset(
                imagePath,
                width: 200, // Adjust image size
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}
