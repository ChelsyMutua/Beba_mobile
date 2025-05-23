import 'dart:io';

import 'package:beba_mobile/components/app_bar.dart';
import 'package:beba_mobile/components/delete_dialog.dart';
import 'package:beba_mobile/components/ticket_type.dart';
import 'package:crypto/crypto.dart';
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
  final String? Function(String?)? validator;

  const FormInputField({
    Key? key,
    required this.title,
    required this.hintText,
    required this.controller,
    this.isRequired = true,
    this.maxLines = 1,
    this.keyboardType,
    this.validator, 
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
  String? _selectedCategoryId;
  String? _createdCategoryId;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  File? _organizerLogoFile;
  double _logoUploadProgress = 0.0;

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

  Future<void> _pickLogoImage() async {
    try {
      // Create an instance of ImagePicker if not a global field
      final ImagePicker picker = ImagePicker();

      // Pick from gallery, can customize as needed
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _organizerLogoFile = File(pickedFile.path);
          _logoUploadProgress = 0.0; // reset progress if you want to keep that
        });
        // _uploadLogo(); // if you still want to do a fake or real upload
      }
    } catch (e) {
      debugPrint('Error picking logo image: $e');
    }
  }

  // void _uploadLogo() async {
  //   setState(() => _logoUploadProgress = 0.0);

  //   // Fake upload example
  //   for (int i = 1; i <= 10; i++) {
  //     await Future.delayed(const Duration(milliseconds: 300));
  //     setState(() => _logoUploadProgress = i / 10);
  //   }
  // }

  void _removeLogoFile() {
    setState(() {
      _organizerLogoFile = null;
      _logoUploadProgress = 0.0;
    });
  }

  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _organizerEmailController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _selectedEventType;
  final List<Map<String, dynamic>> _ticketTypes = [];

  final List<String> _predefinedTicketTypes = [
    'Regular',
    'VIP',
    'VVIP',
    'Free',
    'Early Bird',
    'Student',
    'Advanced',
    'Group of 4',
    'At Gate'
  ];

  final List<Map<String, String>> _eventTypes = [
    {"name": "Sports", "id": "9b5d881e-7366-41e8-a141-b6819c810271"},
    {"name": "Concert", "id": "f33fbe5c-ad17-4eef-aca6-70104270459b"},
    {"name": "Theater", "id": "fa06def7-a366-40d2-b362-1d7c898bf495"},
    {"name": "Family & kids", "id": "7250b16d-ad3f-4373-aaea-3d0e9d560889"},
    {"name": "Art & Exhibitions", "id": "cee56953-a3fb-48f5-bfb9-3ffd4e611b16"},
    {"name": "Comedy", "id": "0d74cb47-22b7-4022-8149-1603a7775179"},
    {"name": "Movies & Films", "id": "748ae935-795f-4d9f-b605-1ceec9245b5e"},
    {"name": "Festivals", "id": "d9e98234-44a1-498b-a44f-7aa780d6632f"},
    {
      "name": "Education & Workshops",
      "id": "89a91fab-66c5-476f-91ff-2805b2f0830a"
    },
    {"name":"Tours & Travel","id":"a4e1bd1c-10bd-4349-b321-a81ca06f0965"}
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
              "d28233ab4f263d65184ff7803dc8d93e22fee9e02ecce07956f9edfd7c2e044a",
          // "34a17966ce9f9a7f8b27ef35007c57051660ce144ab919b768a65e5aea26fb17",
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
              "d28233ab4f263d65184ff7803dc8d93e22fee9e02ecce07956f9edfd7c2e044a",
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
String? posterPublicId;

if (_selectedImage != null) {
  Map<String, String>? uploadResult = await uploadImageToCloudinary(_selectedImage!);
  if (uploadResult == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Image upload failed. Please try again.")),
    );
    return;
  }
  imageUrl = uploadResult['secure_url'];
  posterPublicId = uploadResult['public_id'];

  // Now you can use publicId if needed
}

// Upload the organizer logo if one is selected.
String? organizerLogoUrl;
String? organizerPublicId;

print("Organizer public ID: $organizerPublicId");

if (_organizerLogoFile != null) {
  Map<String, String>? logoUploadResult = await uploadImageToCloudinary(_organizerLogoFile!);
  if (logoUploadResult == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Organizer logo upload failed. Please try again.")),
    );
    return;
  }
  organizerLogoUrl = logoUploadResult['secure_url'];
  organizerPublicId = logoUploadResult['public_id']; 

    print("Organizer public ID: $organizerPublicId");
} else {
  print("No organizer logo selected."); 
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
      "category_id": _selectedCategoryId,
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
      "poster_public_id": posterPublicId,  
      // Use the venue name from the selected location data, or fallback to the controller's text.
      "location": _locationController.text,
      "organizer_logo_url": organizerLogoUrl,
      "organizer_public_id": organizerPublicId, 
      "organizer_email": _organizerEmailController.text
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
              "d28233ab4f263d65184ff7803dc8d93e22fee9e02ecce07956f9edfd7c2e044a",
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

Future<Map<String, String>?> uploadImageToCloudinary(File imageFile) async {
  final String cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  final String uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';
  final String apiKey = dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  final String apiSecret = dotenv.env['CLOUDINARY_API_SECRET'] ?? '';

  if (cloudName.isEmpty || apiKey.isEmpty || apiSecret.isEmpty) {
    print("Cloudinary configuration is missing.");
    return null;
  }

  final Uri url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/upload');
  
  // Using signed upload with API key and secret
  final int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  
  // Create a map of parameters to sign
  Map<String, String> paramsToSign = {
    'timestamp': timestamp.toString(),
  };
  
  // Add upload preset if available, but not required for signed uploads
  if (uploadPreset.isNotEmpty) {
    paramsToSign['upload_preset'] = uploadPreset;
  }
  
  // Build the string to sign by sorting parameters alphabetically
  List<String> sortedKeys = paramsToSign.keys.toList()..sort();
  String paramsStr = sortedKeys
      .map((key) => "$key=${paramsToSign[key]}")
      .join('&');
  
  // Create the signature
  final String signature = sha1.convert(utf8.encode(paramsStr + apiSecret)).toString();
  
  print("Signature details - Timestamp: $timestamp, Params: $paramsStr");
  
  // Create the request
  var request = http.MultipartRequest('POST', url);
  request.fields['api_key'] = apiKey;
  request.fields['timestamp'] = timestamp.toString();
  request.fields['signature'] = signature;
  
  // Add upload preset if available
  if (uploadPreset.isNotEmpty) {
    request.fields['upload_preset'] = uploadPreset;
  }
  
  request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
  
  print("Sending signed request to $url with fields: ${request.fields}");
  
  try {
    var response = await request.send();
    if (response.statusCode == 200) {
      final resStream = await http.Response.fromStream(response);
      print("Raw response: ${resStream.body}");
      final Map<String, dynamic> data = jsonDecode(resStream.body);
      print("Cloudinary upload successful: ${data['secure_url']}");
      return {
        'secure_url': data['secure_url'],
        'public_id': data['public_id']
      };
    } else {
      print("Cloudinary upload failed with status: ${response.statusCode}");
      final resStream = await http.Response.fromStream(response);
      print("Error response: ${resStream.body}");
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
                            // 1) Location
                            if (_selectedLocationData != null) {
                              print(
                                  "_selectedLocationData: $_selectedLocationData");
                              await _sendVenueData(_selectedLocationData!);
                            }
                            // 2) Create event
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

                  DottedBorder(
                    color: const Color(0xFFFAA173),
                    strokeWidth: 2,
                    dashPattern: const [6, 3],
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _organizerLogoFile == null
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Upload the Organizer Logo',
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: _pickLogoImage,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF01DCDC),
                                  ),
                                  child: const Text(
                                    'Choose file',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _organizerLogoFile!.path
                                            .split('/')
                                            .last,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: _pickLogoImage,
                                          icon: const Icon(Icons.edit,
                                              color: Colors.black),
                                        ),
                                        IconButton(
                                          onPressed: _removeLogoFile,
                                          icon: const Icon(Icons.delete,
                                              color: Colors.black),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                // const SizedBox(height: 8),
                                // LinearProgressIndicator(
                                //   value: _logoUploadProgress,
                                //   minHeight: 5,
                                //   backgroundColor: Colors.grey[300],
                                //   color: const Color(0xFF01DCDC),
                                // ),
                              ],
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

                    // Organizer Email
                    FormInputField(
                      title: 'Organizer Email',
                      hintText: 'Enter organizer email',
                      controller: _organizerEmailController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email is required';
                        }
                        
                        // Email validation regex pattern
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        
                        return null;
                      },
                      isRequired: true,
                    ),

                    // Descriptive text below email field
                    Padding(
                      padding: const EdgeInsets.only(top: 1, left: 8),
                      child: Text(
                        'We need your email to send you daily updates and analytics about your event ticket sales.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
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
                        value: _selectedCategoryId,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        hint: const Text('Select event type'),
                        items: _eventTypes.map((event) {
                          return DropdownMenuItem(
                            value: event["id"], // ✅ Store the event's ID
                            child: Text(
                                event["name"]!), // ✅ Display the event's name
                          );
                        }).toList(),
                        onChanged: (String? selectedId) {
                          setState(() {
                            _selectedCategoryId =
                                selectedId; // ✅ Store the selected event ID
                          });
                        },
                      )
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

             FocusScope.of(context).unfocus();

            // 5. Force a rebuild if needed
            setState(() {});
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
