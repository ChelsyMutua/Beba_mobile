import 'package:flutter/material.dart';
import '../models/event.dart';

class EventCard extends StatelessWidget {
  final Event event;

  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1855E2), // Background color
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date & Location Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Date Circle
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                ),
                child: Center(
                  child: Text(
                    "${event.date}\n${event.month}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Location & Venue
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.location,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    event.venue,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Organizer Name
          Text(
            event.organizer,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),

          // Event Title
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 10),

          // Attendees List
          // Row(
          //   children: [
          //     ...event.attendees.take(2).map((image) => Padding(
          //           padding: const EdgeInsets.only(right: 5),
          //           child: CircleAvatar(
          //             radius: 12,
          //             backgroundImage: AssetImage(image),
          //           ),
          //         )),
          //     if (event.attendees.length > 2)
          //       Container(
          //         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          //         decoration: BoxDecoration(
          //           color: Colors.white,
          //           borderRadius: BorderRadius.circular(10),
          //         ),
          //         child: Text(
          //           "+${event.attendees.length - 2}",
          //           style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          //         ),
          //       ),
          //   ],
          // ),
        ],
      ),
    );
  }
}
