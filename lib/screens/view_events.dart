import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event.dart';
import '../components/event_card.dart';
import '../screens/form/update_event_form.dart'; // Import your update form page

class ViewEventsScreen extends StatefulWidget {
  const ViewEventsScreen({super.key});

  @override
  _ViewEventsScreenState createState() => _ViewEventsScreenState();
}

class _ViewEventsScreenState extends State<ViewEventsScreen>
    with AutomaticKeepAliveClientMixin {
  // A static variable that caches events between widget instances.
  static List<Event>? _cachedEvents;
  late Future<List<Event>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    if (_cachedEvents != null) {
      _eventsFuture = Future.value(_cachedEvents);
    } else {
      _eventsFuture = fetchEvents().then((events) {
        _cachedEvents = events;
        return events;
      });
    }
  }

  Future<List<Event>> fetchEvents() async {
    final url = Uri.parse(
        "https://backendcode-production-6e08.up.railway.app/api/events");
    final response = await http.get(url, headers: {
      "x-api-key":
          "34a17966ce9f9a7f8b27ef35007c57051660ce144ab919b768a65e5aea26fb17"
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Event.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load events");
    }
  }

  /// Clears the cached events and reloads from the API.
  void _refreshEvents() {
    setState(() {
      _cachedEvents = null;
      _loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required when using AutomaticKeepAliveClientMixin
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
        appBar: AppBar(
          title: const Text(" Your Events 🎭"),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshEvents,
            ),
          ],
        ),
        body: FutureBuilder<List<Event>>(
          future: _eventsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No events found."));
            } else {
              final events = snapshot.data!;
              return ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () async {
                      // Print event details to the terminal
                      print("Event tapped:");
                      print("ID: ${events[index].id}");
                      print("Title: ${events[index].title}");
                      print("Organizer: ${events[index].organizer}");
                      print("Date: ${events[index].date}");
                      // print("Time: ${events[index].timerange}");
                      print("Location: ${events[index].location}");
                      print("Venue: ${events[index].venue}");
                      // Navigate to UpdateEventForm when tapping the card.
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UpdateEventForm(
                            eventId: events[index].id,
                            initialData: events[index].toJson(),
                          ),
                        ),
                      );
                      // Optionally refresh events if an update was made.
                      if (updated != null) {
                        _refreshEvents();
                      }
                    },
                    child: EventCard(event: events[index]),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
