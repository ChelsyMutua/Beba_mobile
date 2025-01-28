import 'package:flutter/material.dart';
import '../models/event.dart';
import '../components/event_card.dart';

class ViewEventsScreen extends StatelessWidget {
  const ViewEventsScreen({super.key});

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
        backgroundColor: Colors.transparent, // Ensures gradient is visible
        appBar: AppBar(
          title: const Text(" Your Events 🎭"),
          backgroundColor: Colors.transparent, // Transparent AppBar
          elevation: 0, // Removes shadow for a clean look
        ),
        body: ListView.builder(
          itemCount: sampleEvents.length,
          itemBuilder: (context, index) {
            return EventCard(event: sampleEvents[index]);
          },
        ),
      ),
    );
  }
}
