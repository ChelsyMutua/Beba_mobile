import 'dart:io';
import 'dart:convert';
import 'package:beba_mobile/components/app_bar.dart';
import 'package:beba_mobile/components/ticket_type.dart';
import 'package:beba_mobile/screens/event_analytics_page.dart';
import 'package:beba_mobile/screens/form/form.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bottom_picker/bottom_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dotted_border/dotted_border.dart';

import '../event_analytics_page.dart';



class UpdateEventForm extends StatefulWidget {
  final String eventId; // The ID of the event to update
  final Map<String, dynamic> initialData; // Data from fetch events API

  const UpdateEventForm({Key? key, required this.eventId, required this.initialData}) : super(key: key);

  @override
  _UpdateEventFormState createState() => _UpdateEventFormState();
}

class _UpdateEventFormState extends State<UpdateEventForm> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _eventNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _selectedEventType;
  List<Map<String, dynamic>> _selectedTickets = [];

  final List<String> _predefinedTicketTypes = ['Regular', 'VIP', 'Early Bird', 'Student'];
  final List<String> _eventTypes = [
    'Sports',
    'Concert',
    'Theater',
    'Family & kids',
    'Art & Exhibitions',
    'Comedy',
    'Movies & Films',
    'Festivals',
    'Education & Workshops'
  ];

  @override
  void initState() {
    super.initState();
    // Prepopulate controllers from the initial data
    _eventNameController = TextEditingController(text: widget.initialData['title'] ?? '');
    _descriptionController = TextEditingController(text: widget.initialData['description'] ?? '');
    _locationController = TextEditingController(text: widget.initialData['location'] ?? '');
    
    // Parse dates if available (adjust according to your API format)
    if (widget.initialData['date'] != null) {
      _startDate = DateTime.tryParse(widget.initialData['date']);
    }
    if (widget.initialData['time'] != null) {
      DateTime? dt = DateTime.tryParse(widget.initialData['time']);
      if (dt != null) {
        _startTime = TimeOfDay.fromDateTime(dt);
      }
    }
    // Pre-populate tickets if available. Assume API sends a "ticket_types" list.
    if (widget.initialData['ticket_types'] != null) {
      _selectedTickets = List<Map<String, dynamic>>.from(widget.initialData['ticket_types']);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  // Function to update event using a PUT request
  Future<void> _updateEvent() async {
    final url = Uri.parse(
        "https://backendcode-production-6e08.up.railway.app/api/events/${widget.eventId}");

    // Ensure at least one ticket type exists
    if (_selectedTickets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You must add at least one ticket type!")),
      );
      return;
    }

    // Sanitize ticket data: remove 'color' property if present
    List<Map<String, dynamic>> sanitizedTickets = _selectedTickets.map((ticket) {
      final sanitized = Map<String, dynamic>.from(ticket);
      sanitized.remove('color');
      return sanitized;
    }).toList();

    // Build pricing and ticket_availability maps
    Map<String, dynamic> pricing = {};
    Map<String, dynamic> ticketAvailability = {};
    for (var ticket in sanitizedTickets) {
      String type = ticket['type'].toString().toLowerCase();
      pricing[type] = ticket['price'];
      ticketAvailability[type] = ticket['quantity'];
    }

    // Format date and time
    String? startDateStr = _startDate != null ? _startDate!.toIso8601String() : null;
    String? endDateStr = _endDate != null ? _endDate!.toIso8601String() : null;
    String? timeRangeStr = (_startTime != null && _endTime != null)
        ? "${_startTime!.format(context)} - ${_endTime!.format(context)}"
        : null;

    final Map<String, dynamic> eventData = {
      "title": _eventNameController.text,
      "description": _descriptionController.text,
      "location": _locationController.text,
      "date": startDateStr,
      "end_date": endDateStr,
      "time_range": timeRangeStr,
      "ticket_types": sanitizedTickets,
      "pricing": pricing,
      "ticket_availability": ticketAvailability,
      // You can add other fields as needed.
    };

    print("📤 Sending update data: ${jsonEncode(eventData)}");

    try {
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "x-api-key": "099b90d8e22347f1160f33ab460f4ae405da4b0e6b4f40e49f2f7a9f4f622a7a",
        },
        body: jsonEncode(eventData),
      );

      if (response.statusCode == 200) {
        print("✅ Event updated successfully!");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Event updated successfully!")),
        );
        Navigator.pop(context);
      } else {
        print("❌ Error: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update event: ${response.body}")),
        );
      }
    } catch (error) {
      print("❌ Network Error: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network error. Please try again.")),
      );
    }
  }

  // Navigate to the analytics page
  void _openAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EventAnalyticsPage(eventId: widget.eventId)),
    );
  }

  void _openTicketSelector() async {
    final newTickets = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (context) => TicketSelector(onTicketsSelected: (tickets) {
        Navigator.of(context).pop(tickets);
      }),
    );
    if (newTickets != null) {
      setState(() {
        _selectedTickets.addAll(newTickets);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FormAppBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Update Event Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _updateEvent();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF01DCDC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(45),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Update Event',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Analytics Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _openAnalytics,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(45),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Analytics',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                splashFactory: NoSplash.splashFactory,
              ),
              child: const Text(
                'Go back',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Theme(
          data: Theme.of(context).copyWith(
            textSelectionTheme: const TextSelectionThemeData(
              cursorColor: Colors.black,
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(14),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Update Event',
                      style: TextStyle(fontSize: 18, color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Poster Upload
                  DottedBorder(
                    color: const Color(0xFFFAA173),
                    strokeWidth: 2,
                    dashPattern: const [6, 3],
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(12),
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _selectedImage != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedImage = null;
                                      });
                                    },
                                    icon: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: IconButton(
                                    onPressed: _pickImage,
                                    icon: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : GestureDetector(
                              onTap: _pickImage,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.cloud_upload,
                                    size: 48,
                                    color: Color(0xFF01DCDC),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Upload Event Poster',
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'PNG, JPG up to 10MB',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Event Name
                  FormInputField(
                    title: 'Name of Event',
                    hintText: 'Enter event name',
                    controller: _eventNameController,
                  ),
                  // Description
                  FormInputField(
                    title: 'Short Description',
                    hintText: 'Enter event description',
                    controller: _descriptionController,
                    maxLines: 3,
                  ),
                  // Event Start Date
                  DateTimePickerField(
                    label: "Set Start Date & Time",
                    onDateTimeSelected: (dateTime) {
                      setState(() {
                        _startDate = dateTime;
                        _startTime = TimeOfDay.fromDateTime(dateTime);
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  // Event End Date
                  DateTimePickerField(
                    label: "Set End Date & Time",
                    onDateTimeSelected: (dateTime) {
                      setState(() {
                        _endDate = dateTime;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  // Location
                  FormInputFieldLocation(
                    title: 'Location',
                    hintText: 'Enter event location',
                    controller: _locationController,
                    onPlaceSelected: (locationData) {
                      // Handle location selection
                    },
                  ),
                  const SizedBox(height: 24),
                  // Event Type
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Event Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedEventType,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        hint: const Text('Select event type'),
                        items: _eventTypes.map((String type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          setState(() => _selectedEventType = value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Ticket Types
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ticket Types',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._selectedTickets.map((ticket) => TicketTypeItem(
                            type: ticket['type'],
                            quantity: ticket['quantity'].toString(),
                            onDelete: () {
                              setState(() {
                                _selectedTickets.remove(ticket);
                              });
                            },
                          )),
                      TextButton(
                        onPressed: _openTicketSelector,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF01DCDC),
                                Color(0xFFFAA173),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Add Ticket Type',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 150),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
