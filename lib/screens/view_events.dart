import 'package:beba_mobile/models/venue.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event.dart';
import '../components/event_card.dart';
import '../screens/form/update_event_form.dart';

class DeleteEventConfirmationDialog extends StatelessWidget {
  final String eventTitle;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  const DeleteEventConfirmationDialog({
    Key? key,
    required this.eventTitle,
    required this.onDelete,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Are you sure you want\nto delete this event?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This event will be permanently deleted.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event,
                    color: Colors.grey[700],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      eventTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: onDelete,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Color(0xFFff002b),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ViewEventsScreen extends StatefulWidget {
  const ViewEventsScreen({super.key});

  @override
  _ViewEventsScreenState createState() => _ViewEventsScreenState();
}

class _ViewEventsScreenState extends State<ViewEventsScreen>
    with AutomaticKeepAliveClientMixin {
  late Future<List<Event>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    _eventsFuture = fetchEvents();
  }

  Future<List<Event>> fetchEvents() async {
    final url = Uri.parse(
        "https://backendcode-production-6e08.up.railway.app/api/events");
       
    final response = await http.get(url, headers: {
      "x-api-key":
          "d28233ab4f263d65184ff7803dc8d93e22fee9e02ecce07956f9edfd7c2e044a",
      "Cache-Control": "no-cache",
      "Pragma": "no-cache",
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      print(data);
      return data.map((json) => Event.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load events");
    }
  }

  Future<bool> deleteEvent(String eventId) async {
    final url = Uri.parse(
        "https://backendcode-production-6e08.up.railway.app/api/events/$eventId");
       
    final response = await http.delete(url, headers: {
      "x-api-key":
          "d28233ab4f263d65184ff7803dc8d93e22fee9e02ecce07956f9edfd7c2e044a",
    });

    return response.statusCode == 200;
  }

  void _showDeleteConfirmation(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return DeleteEventConfirmationDialog(
          eventTitle: event.title,
          onDelete: () async {
            Navigator.of(dialogContext).pop(); // Close dialog
            
            // Show loading indicator
            final loadingContext = context;
            showDialog(
              context: loadingContext,
              barrierDismissible: false,
              builder: (BuildContext loaderContext) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
            );
            
            try {
              final success = await deleteEvent(event.id);
              
              // Close loading dialog
              Navigator.of(loadingContext).pop();
              
              if (success) {
                ScaffoldMessenger.of(loadingContext).showSnackBar(
                  const SnackBar(content: Text('Event deleted successfully')),
                );
                _refreshEvents();
              } else {
                ScaffoldMessenger.of(loadingContext).showSnackBar(
                  const SnackBar(content: Text('Failed to delete event')),
                );
              }
            } catch (e) {
              // Close loading dialog
              Navigator.of(loadingContext).pop();
              
              ScaffoldMessenger.of(loadingContext).showSnackBar(
                SnackBar(content: Text('Error: ${e.toString()}')),
              );
            }
          },
          onCancel: () {
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );
  }

  void _refreshEvents() {
    setState(() {
      _loadEvents();
    });
  }

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
                  return Stack(
                  clipBehavior: Clip.antiAlias,
                    children: [
                      InkWell(
                        onTap: () async {
                          // Print event details to the terminal
                          print("Event tapped:");
                          print("ID: ${events[index].id}");
                          print("Title: ${events[index].title}");
                          print("Organizer: ${events[index].organizerLogo}");
                          print("Date: ${events[index].startDate}");
                          print("Venue: ${events[index].venueId}");
                          
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
                          if (updated == true) {
                            _refreshEvents();
                          }
                        },
                        child: EventCard(event: events[index]),
                      ),
                      Positioned(
                        top: 10,
                        right: 15,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              _showDeleteConfirmation(context, events[index]);
                            },
                          ),
                        ),
                      ),
                    ],
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