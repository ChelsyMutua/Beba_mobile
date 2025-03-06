import 'dart:convert';

import 'package:beba_mobile/models/venue.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import 'package:http/http.dart' as http;

class EventCard extends StatelessWidget {
  final Event event;

  const EventCard({super.key, required this.event});


  Future<Venue> fetchVenue(String venueId) async {
  final url = Uri.parse("https://backendcode-production-6e08.up.railway.app/api/venues/$venueId");
  final response = await http.get(url, headers: {
    "x-api-key": "d28233ab4f263d65184ff7803dc8d93e22fee9e02ecce07956f9edfd7c2e044a"
  });

  if (response.statusCode == 200) {
    final Map<String, dynamic> jsonData = jsonDecode(response.body);
    return Venue.fromJson(jsonData);
  } else {
    throw Exception("Failed to load venue");
  }
}

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
              Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                ),
                child: Center(
                  child: Text(
                    // Display the day and abbreviated month from createdAt:
                    "${event.createdAt.day}\n${DateFormat.MMM().format(event.createdAt)}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
              

              // Location & Venue
              Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Use FutureBuilder to display the venue name using the venueId:
                  event.venueId != null
                      ? FutureBuilder<Venue>(
                          future: fetchVenue(event.venueId!),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Text("Loading venue...",
                                  style: TextStyle(color: Colors.white70));
                            } else if (snapshot.hasError) {
                              return const Text("Error loading venue",
                                  style: TextStyle(color: Colors.white70));
                            } else if (!snapshot.hasData) {
                              return const Text("No venue info",
                                  style: TextStyle(color: Colors.white70));
                            } else {
                              return Text(
                                snapshot.data!.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              );
                            }
                          },
                        )
                      : const Text("No venue assigned",
                          style: TextStyle(color: Colors.white70)),
                ],
              ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Organizer Name
          // Text(
          //   event.organizer,
          //   style: const TextStyle(
          //     fontSize: 14,
          //     color: Colors.white70,
          //   ),
          // ),

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
