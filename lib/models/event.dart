import 'package:intl/intl.dart';

class Event {
  final String id; // Add an id field
  final String date;
  final String month;
  final String location;
  final String venue;
  final String organizer;
  final String title;
  final List<String> attendees;

  Event({
    required this.id,
    required this.date,
    required this.month,
    required this.location,
    required this.venue,
    required this.organizer,
    required this.title,
    required this.attendees,
  });

  // Factory constructor to create an Event from JSON
  factory Event.fromJson(Map<String, dynamic> json) {
    // For demonstration, parse the id and use placeholders for fields not provided by your API
    return Event(
      id: json['id'] ?? '',
      date: json["ticket_sale_start"] != null
          ? DateTime.tryParse(json["ticket_sale_start"])?.day.toString() ?? ""
          : "",
      month: json["ticket_sale_start"] != null
          ? DateFormat("MMM").format(DateTime.tryParse(json["ticket_sale_start"])!)
          : "",
      location: json["location"] ?? "Unknown Location",
      venue: json["venue"] ?? "Unknown Venue",
      organizer: json["organizer"] ?? "Unknown Organizer",
      title: json["title"] ?? "",
      attendees: [], // Adjust if API provides attendee info
    );
  }

  // Convert an Event to JSON (for updating purposes)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': '', // Fill as needed
      'location': location,
      'date': date,
      'time': '', // Fill as needed
      // Add other fields as needed
    };
  }
}
