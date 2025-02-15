import 'dart:io';

import 'package:beba_mobile/components/app_bar.dart';
import 'package:beba_mobile/components/delete_dialog.dart';
import 'package:beba_mobile/components/ticket_type.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:bottom_picker/bottom_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Reusable form input widget
class FormInputField extends StatelessWidget {
  final String title;
  final String hintText;
  final bool isRequired;
  final TextEditingController controller;
  final int? maxLines;
  final TextInputType? keyboardType;

  const FormInputField({
    Key? key,
    required this.title,
    required this.hintText,
    required this.controller,
    this.isRequired = true,
    this.maxLines = 1,
    this.keyboardType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                }
              : null,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class CreateEventForm extends StatefulWidget {
  const CreateEventForm({Key? key}) : super(key: key);

  @override
  CreateEventFormState createState() => CreateEventFormState();
}

class CreateEventFormState extends State<CreateEventForm> {
  bool _isLoading = false;
  // this is the location controller
  Map<String, dynamic>? _selectedLocationData;

  String? _selectedVenueId; //keep track of newly creted venue Id's
  String? _createdCategoryId;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  String formatTime(DateTime dateTime) {
    return DateFormat.jm().format(dateTime); // Outputs: "10:30 AM"
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
      // Handle error
      debugPrint('Error picking image: $e');
    }
  }

  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _selectedEventType;
  final List<Map<String, dynamic>> _ticketTypes = [];

  final List<String> _predefinedTicketTypes = [
    'Regular',
    'VIP',
    'Early Bird',
    'Student'
  ];

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

  // get venue uuid
  Future<void> _sendVenueData(Map<String, dynamic> locationData) async {
    final url = Uri.parse(
        "https://backendcode-production-6e08.up.railway.app/api/venues");

    // Build the JSON you want to send to create the venue
    final venuePayload = {
      "name": locationData['name'], // or "J's Arcade"
      "address": locationData['address'], // e.g. "Thome road, Nairobi"
      "city": "Nairobi", // or derive from locationData
      "country": "Kenya",
      "postal_code": "00100",
      "state": "Nairobi County",
      "capacity": "500", // set this to just a default
      "latitude": locationData['latitude'], // from the GooglePlaceAutoComplete
      "longitude": locationData['longitude'],
      "google_place_id": locationData['placeId'],
      // Any other fields your venueController expects
    };

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "x-api-key":
              "f5150a7983ef9fb0b7f1023da3834b3fc13208546e37876b84658cdfd1f312ea",
        },
        body: jsonEncode(venuePayload),
      );

      if (response.statusCode == 201) {
        // Parse the response to get the newly created venue data
        final data = jsonDecode(response.body);

        print('Venue creation response status: ${response.statusCode}');
        print('Venue creation response body: ${response.body}');
        // Store the ID in _selectedVenueId for later
        setState(() {
          _selectedVenueId = data['id']; // The UUID returned by the backend
        });

        print("Venue created successfully: $data");
      } else {
        print("Failed to create venue: ${response.body}");
      }
    } catch (error) {
      print("Error creating venue: $error");
    }
  }

  Future<void> _createCategory() async {
    final url = Uri.parse(
        "https://backendcode-production-6e08.up.railway.app/api/categories");

    final categoryPayload = {
      "name": _selectedEventType,
      "description": _descriptionController.text,
      // Include any other fields your model expects
    };

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "x-api-key":
              "f5150a7983ef9fb0b7f1023da3834b3fc13208546e37876b84658cdfd1f312ea",
        },
        body: jsonEncode(categoryPayload),
      );

      if (response.statusCode == 201) {
        // Parse the JSON response
        final data = jsonDecode(response.body);
        // data['id'] is the newly created category's UUID
        setState(() {
          _createdCategoryId = data['id'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Category Created! ID: $_createdCategoryId")),
        );
      } else {
        print("Error creating category: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to create category.")),
        );
      }
    } catch (error) {
      print("Network or Server Error: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network Error. Try again.")),
      );
    }
  }

  Future<void> _createEvent() async {
    final url = Uri.parse(
        "https://backendcode-production-6e08.up.railway.app/api/events");

    // Ensure at least one ticket type exists
    if (_selectedTickets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You must add at least one ticket type!")),
      );
      return;
    }

    // If an image is selected, upload it to Cloudinary.
    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadImageToCloudinary(_selectedImage!);
      if (imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Image upload failed. Please try again.")),
        );
        return;
      }
    }

    // If a venue/location was selected, send its data to the venue endpoint.
    // (Assuming _sendVenueData is defined and returns a response or simply prints a message.)
    // if (_selectedLocationData != null) {
    //   await _sendVenueData(_selectedLocationData!);
    // }

    // Sanitize ticket data (remove color property)
    List<Map<String, dynamic>> sanitizedTickets =
        _selectedTickets.map((ticket) {
      final sanitized = Map<String, dynamic>.from(ticket);
      sanitized.remove('color');
      return sanitized;
    }).toList();

    // Build pricing and ticket_availability objects from sanitized tickets
    Map<String, dynamic> pricing = {};
    Map<String, dynamic> ticketAvailability = {};
    for (var ticket in sanitizedTickets) {
      String type = ticket['type'].toString().toLowerCase();
      pricing[type] = ticket['price'];
      ticketAvailability[type] = ticket['quantity'];
    }

    // Validate dates & times before sending
    String? startDateStr =
        _startDate != null ? _startDate!.toIso8601String() : null;
    String? endDateStr = _endDate != null ? _endDate!.toIso8601String() : null;
    String? timeRangeStr;
    if (_startTime != null && _endTime != null) {
      final now = DateTime.now();
      final startDateTime = DateTime(
          now.year, now.month, now.day, _startTime!.hour, _startTime!.minute);
      final endDateTime = DateTime(
          now.year, now.month, now.day, _endTime!.hour, _endTime!.minute);
      timeRangeStr =
          "${DateFormat('h:mm a').format(startDateTime)} - ${DateFormat('h:mm a').format(endDateTime)}";
    } else {
      timeRangeStr = null;
    }
    String? startTimeStr =
        _startTime != null ? _startTime!.format(context) : null;

    final DateTime today = DateTime.now();
    final String ticketSalesStartStr = today.toIso8601String();
    final DateTime? eventEndDate = _endDate;
    final String? ticketSaleEndStr = eventEndDate != null
        ? eventEndDate.add(Duration(days: 1)).toIso8601String()
        : null;

    final Map<String, dynamic> eventData = {
      "title": _eventNameController.text,
      "description": _descriptionController.text,
      "category_id": _createdCategoryId,
      "venue_id": _selectedVenueId,
      "start_date": startDateStr,
      "time": startTimeStr,
      "end_date": endDateStr,
      "time_range": timeRangeStr,
      "ticket_types": sanitizedTickets,
      "ticket_availability": ticketAvailability,
      "pricing": pricing,
      "ticket_sale_start": ticketSalesStartStr,
      "ticket_sale_end": ticketSaleEndStr,
      "image_url": imageUrl,
      // Use the venue name from the selected location data, or fallback to the controller's text.
      "location": _locationController.text
    };

    print("_selectedLocationData: $_selectedLocationData");
    print(">>>>>>><<<<<<<<<<<<<<");

    print("📤 Sending event data: ${jsonEncode(eventData)}");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "x-api-key":
              "f5150a7983ef9fb0b7f1023da3834b3fc13208546e37876b84658cdfd1f312ea",
        },
        body: jsonEncode(eventData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print("✅ Event created successfully!");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Event created successfully!")),
        );
        Navigator.pop(context);
      } else {
        print("❌ Error: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to create event: ${response.body}")),
        );
      }
    } catch (error) {
      print("❌ Network Error: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network error. Please try again.")),
      );
    }
  }

  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    // Get your Cloudinary settings from environment variables
    final String cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
    final String uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      print("Cloudinary configuration is missing.");
      return null;
    }

    // Cloudinary upload endpoint
    final Uri url =
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/upload');

    // Create a multipart request
    var request = http.MultipartRequest('POST', url);
    // Set the unsigned preset
    request.fields['upload_preset'] = uploadPreset;
    // Attach the file
    request.files
        .add(await http.MultipartFile.fromPath('file', imageFile.path));

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        // Parse the response
        final resStream = await http.Response.fromStream(response);
        final Map<String, dynamic> data = jsonDecode(resStream.body);
        print("Cloudinary upload successful: ${data['secure_url']}");
        return data['secure_url']; // This is the URL to the uploaded image.
      } else {
        print("Cloudinary upload failed with status: ${response.statusCode}");
        return null;
      }
    } catch (error) {
      print("Cloudinary upload error: $error");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FormAppBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        // Keep your existing Container properties
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Your two buttons (Create Event + Go Back) here
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            _isLoading = true;
                          });
                          try {
                            // 1) Fetch category ID
                            await _createCategory();

                            // 2) Location
                            if (_selectedLocationData != null) {
                              print(
                                  "_selectedLocationData: $_selectedLocationData");
                              await _sendVenueData(_selectedLocationData!);
                            }
                            // 3) Create event
                            await _createEvent();
                          } finally {
                            setState(() {
                              _isLoading = false;
                            });
                          }
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
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.black),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Create Event',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
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
              cursorColor: Colors.black, // The cursor color you want
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
                  // Center(
                  //   child: const Text(
                  //     'MY EVENTS',
                  //     style: TextStyle(
                  //       fontSize: 24,
                  //       fontWeight: FontWeight.bold,
                  //       color: Colors.black,
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(height: 8),

                  const Center(
                    child: Text(
                      'Create Event',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                      ),
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

                  // this is the Event start date
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

                  //this is the end Date
                  DateTimePickerField(
                      label: "Set End Date & Time",
                      onDateTimeSelected: (dateTime) {
                        setState(() {
                          _endDate = dateTime;
                          _endTime = TimeOfDay.fromDateTime(dateTime);
                        });
                      }),

                  const SizedBox(height: 24),

                  // Location

                  FormInputFieldLocation(
                    title: 'Location',
                    hintText: 'Enter event location',
                    controller: _locationController,
                    onPlaceSelected: (locationData) {
                      // Print the selected location data (for debugging)
                      print('Selected location: $locationData');

                      // Save the location data to the state variable
                      setState(() {
                        _selectedLocationData = locationData;
                      });
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

                      // Display Selected Tickets
                      ..._selectedTickets.map((ticket) => TicketTypeItem(
                            type: ticket['type'],
                            quantity: ticket['quantity'].toString(),
                            onDelete: () {
                              setState(() {
                                _selectedTickets
                                    .remove(ticket); // Remove from parent state
                              });
                            },
                          )),

                      // Open TicketSelector on Button Click
                      TextButton(
                        onPressed: () => _openTicketSelector(),
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
                                Color(0xFF01DCDC), // Cyan/Turquoise
                                Color(0xFFFAA173), // Peach/Orange
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

  List<Map<String, dynamic>> _selectedTickets = [];

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
}

class DateTimePickerField extends StatefulWidget {
  final Function(DateTime) onDateTimeSelected;
  final String label; // helps us pass the label params

  const DateTimePickerField(
      {Key? key, required this.onDateTimeSelected, required this.label})
      : super(key: key);

  @override
  _DateTimePickerFieldState createState() => _DateTimePickerFieldState();
}

class _DateTimePickerFieldState extends State<DateTimePickerField> {
  DateTime? _selectedDateTime;

  void _pickDateTime(BuildContext context) {
    BottomPicker.dateTime(
      pickerTitle: Text(widget.label),
      pickerTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
      onSubmit: (date) {
        setState(() {
          _selectedDateTime = date;
        });
        widget.onDateTimeSelected(date);
      },
      onCloseButtonPressed: () {
        Navigator.pop(context); // 🔥 This will close the BottomPicker properly
      },
      minDateTime: DateTime.now(), // Minimum date is today
      maxDateTime:
          DateTime.now().add(const Duration(days: 365)), // Maximum 1 year ahead
      gradientColors: const [
        Color(0xff35D0C6),
        Color(0xffF1A377),
      ],
      //  buttonText()
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),

        // Date-Time Picker UI (Styled Container)
        GestureDetector(
          onTap: () => _pickDateTime(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[200], // Use grey for a modern feel
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: const Icon(Icons.calendar_today, color: Colors.black),
                ), // Calendar icon
                Text(
                  _selectedDateTime == null
                      ? "Select Date & Time"
                      : DateFormat("EEEE, d MMMM yyyy HH:mm")
                          .format(_selectedDateTime!),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class FormInputFieldLocation extends StatefulWidget {
  final String title;
  final String hintText;
  final TextEditingController controller;
  final Function(Map<String, dynamic>)? onPlaceSelected; // Add this callback
  final String initialValue;

  const FormInputFieldLocation({
    Key? key,
    required this.title,
    required this.hintText,
    required this.controller,
    this.onPlaceSelected,
    this.initialValue = '',
  }) : super(key: key);

  @override
  State<FormInputFieldLocation> createState() => _FormInputFieldLocationState();
}

class _FormInputFieldLocationState extends State<FormInputFieldLocation> {
  final _focusNode = FocusNode();
  // final _controller = TextEditingController();
  GoogleMapController? mapController;
  // PlacesDetailsResponse? placeDetail;

  @override
  void initState() {
    super.initState();
    // _controller.text = widget.initialValue;

    // Listen to focus changes
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // Handle focus loss if needed
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    // _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GooglePlaceAutoCompleteTextField(
          textEditingController: widget.controller,
          focusNode: _focusNode,
          googleAPIKey: apiKey,
          inputDecoration: InputDecoration(
            hintText: widget.hintText,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          debounceTime: 800,
          countries: const ["ke"],
          isLatLngRequired: true,
          getPlaceDetailWithLatLng: (Prediction prediction) {
            // Handle place selection
            final locationData = {
              'placeId': prediction.placeId,
              'name': prediction.description,
              'address': prediction.description,
              'latitude': prediction.lat,
              'longitude': prediction.lng,
            };
            print('Called getPlaceDetailWithLatLng with: $locationData');

            // Call the callback if provided
            if (widget.onPlaceSelected != null) {
              widget.onPlaceSelected!(locationData);
            }
          },
          itemClick: (Prediction prediction) {
            widget.controller.text = prediction.description ?? '';
            widget.controller.selection = TextSelection.fromPosition(
              TextPosition(offset: widget.controller.text.length),
            );

            // If you only need the address, you can do this:
            final locationData = {
              'name': prediction.description,
              'address': prediction.description,
              'placeId': prediction.placeId,
              // lat/lng will be null unless you fetch them yourself
            };
            if (widget.onPlaceSelected != null) {
              widget.onPlaceSelected!(locationData);
            }
          },
        ),
      ],
    );
  }
}

class TicketTypeItem extends StatelessWidget {
  final String type;
  final String quantity;
  final VoidCallback onDelete;

  const TicketTypeItem({
    Key? key,
    required this.type,
    required this.quantity,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('Quantity: $quantity'),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => DeleteConfirmationDialog(
                  ticketType: type,
                  onDelete: () {
                    Navigator.of(context).pop(); // Close the dialog
                    onDelete(); // Execute the delete action
                  },
                  onCancel: () =>
                      Navigator.of(context).pop(), // Just close the dialog
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
