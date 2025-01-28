class Event {
  final String date;
  final String month;
  final String location;
  final String venue;
  final String organizer;
  final String title;
  final List<String> attendees;

  Event({
    required this.date,
    required this.month,
    required this.location,
    required this.venue,
    required this.organizer,
    required this.title,
    required this.attendees,
  });
}

// Sample Data (Later, we can replace this with API fetching)
List<Event> sampleEvents = [
  Event(
    date: "24",
    month: "Sept",
    location: "San Francisco",
    venue: "Golden Gate Pavilion",
    organizer: "Sonic Waves Productions",
    title: "Summer Music Festival",
    attendees: [
      "assets/images/user1.png",
      "assets/images/user2.png",
      "assets/images/user3.png"
    ],
  ),
];
