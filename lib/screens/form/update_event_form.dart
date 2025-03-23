import 'dart:io';
import 'dart:convert';
import 'package:beba_mobile/components/app_bar.dart';
import 'package:beba_mobile/components/location_edit.dart';
import 'package:beba_mobile/components/ticket_type.dart';
import 'package:beba_mobile/models/category.dart';
import 'package:beba_mobile/screens/event_analytics_page.dart';
import 'package:beba_mobile/screens/form/form.dart';
import 'package:crypto/crypto.dart';
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
  // These hold the current file (if picked) or the URL from Cloudinary
  File? _organizerLogoFile;
  double _logoUploadProgress = 0.0;
  String? _existingLogoUrl;

  File? _selectedImage;
  String? _existingPosterUrl;
  final ImagePicker _picker = ImagePicker();

  bool _isUpdatingVenue = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _eventNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _organizerEmailController;

  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _selectedEventType;
  Map<String, dynamic>? _selectedLocation;
  List<Map<String, dynamic>> _selectedTickets = [];

  final List<String> _predefinedTicketTypes = ['Regular', 'VIP', 'VVIP', 'Free', 'At Gate', 'Group of 5', 'Early Bird', 'Student', 'Advanced'];
  final List<String> _eventTypes = [
    'Sports',
    'Concerts',
    'Theater',
    'Family & Kids',
    'Art & Exhibitions',
    'Comedy',
    'Movies & Films',
    'Festivals',
    'Education & Workshops',
    'Tours & Travels'
  ];

  @override
  void initState() {
    super.initState();
    print("Initial data: ${widget.initialData}");


    // Prepopulate controllers from the initial data
    _eventNameController = TextEditingController(text: widget.initialData['title'] ?? '');
    _descriptionController = TextEditingController(text: widget.initialData['description'] ?? '');
     _organizerEmailController = TextEditingController(
    text: widget.initialData['organizer_email'] ?? '',
  );
    print("Description from DB: ${widget.initialData['description']}");

    _locationController = TextEditingController(text: widget.initialData['location'] ?? '');

    // Store existing image URLs from Cloudinary
    _existingLogoUrl = widget.initialData['organizer_logo_url'];
     print("Organizer logo URL: $_existingLogoUrl");
    _existingPosterUrl = widget.initialData['image_url'];
     print("Poster URL: $_existingPosterUrl");

    // Parse dates if available (adjust according to your API format)
    if (widget.initialData['start_date'] != null) {
      _startDate = DateTime.tryParse(widget.initialData['start_date']);
    }

     if (widget.initialData['end_date'] != null) {
      _endDate = DateTime.tryParse(widget.initialData['end_date']);
    }
    if (widget.initialData['time_range'] != null) {
      String timeRangeStr = widget.initialData['time_range']; // e.g., "6:00 AM - 7:07 PM"
      List<String> times = timeRangeStr.split(" - ");
      if (times.length == 2) {
        try {
          DateTime dtStart = DateFormat.jm().parse(times[0]);
          DateTime dtEnd = DateFormat.jm().parse(times[1]);
          _startTime = TimeOfDay.fromDateTime(dtStart);
          _endTime = TimeOfDay.fromDateTime(dtEnd);
        } catch (e) {
          print("Error parsing time_range: $e");
        }
      }
    }

// Parse and merge ticket_availability and pricing from initialData.
// Extract availability and pricing maps from initialData.
final availabilityMap = widget.initialData['ticket_availability'];
final pricingMap = widget.initialData['pricing'] ?? {};

// Debug print the raw pricingMap
print("DEBUG: pricingMap raw = $pricingMap");

// Normalize pricingMap keys to lowercase.
final Map<String, dynamic> normalizedPricingMap = {};
pricingMap.forEach((key, value) {
  normalizedPricingMap[key.toString().toLowerCase()] = value;
});
print("DEBUG: normalizedPricingMap = $normalizedPricingMap");

// Merge availability and pricing into _selectedTickets.
if (availabilityMap != null && availabilityMap is Map) {
  _selectedTickets = availabilityMap.entries.map((entry) {
    String type = entry.key.toString().toLowerCase();
    var quantity = entry.value;
    var price = normalizedPricingMap[type] ?? 0;
    return {
      "type": type,
      "quantity": quantity,
      "price": price,
    };
  }).toList();
  print("DEBUG: _selectedTickets merged = $_selectedTickets");
}



      // Fetch and set the existing event type from category if available.
      if (widget.initialData['category_id'] != null) {
        fetchCategory(widget.initialData['category_id']).then((category) {
          setState(() {
            _selectedEventType = category.name;
             });
        }).catchError((error) {
          print("Error fetching category: $error");
        });
      }
  }


  Future<Category> fetchCategory(String categoryId) async {
  final url = Uri.parse("https://backendcode-production-6e08.up.railway.app/api/categories/$categoryId");
  final response = await http.get(url, headers: {
    "x-api-key": "d28233ab4f263d65184ff7803dc8d93e22fee9e02ecce07956f9edfd7c2e044a",
  });

  if (response.statusCode == 200) {
    final Map<String, dynamic> jsonData = jsonDecode(response.body);
    return Category.fromJson(jsonData);
  } else {
    throw Exception("Failed to load category");
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
          // Clear the existing poster URL so that the new file is displayed
          _existingPosterUrl = null;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _pickLogoImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _organizerLogoFile = File(pickedFile.path);
          _logoUploadProgress = 0.0;
          // Clear the existing logo URL so that the new file is displayed
          _existingLogoUrl = null;
        });
      }
    } catch (e) {
      debugPrint('Error picking logo image: $e');
    }
  }

  // Updated poster picker method
    Future<void> _pickPosterImage() async {
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
            _existingPosterUrl = null;  // Clear existing URL when new file is picked
          });
          
          // Show snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Poster selected successfully!")),
          );
        }
      } catch (e) {
        print("❌ Error picking poster: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to select poster")),
        );
      }
    }

void _editTicket(int index) async {
  final editedTicketList = await showDialog<List<Map<String, dynamic>>>(
    context: context,
    builder: (context) => TicketSelector(
      initialTicket: _selectedTickets[index],
      onTicketsSelected: (tickets) {
        Navigator.of(context).pop(tickets.isNotEmpty ? tickets.first : null);
      },
      onCancel: () {
        Navigator.of(context).pop(null);
      },
    ),
  );

  if (editedTicketList != null && editedTicketList.isNotEmpty) {
    setState(() {
      _selectedTickets[index] = editedTicketList.first;
    });
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

      // Handle venue_id properly
    String venueId = widget.initialData['venue_id'];
    if (_selectedLocation != null && _selectedLocation!.containsKey('placeId')) {
      // Show a loading indicator if needed
      setState(() {
        _isUpdatingVenue = true;
      });
      
      // Update the existing venue with new location data
      bool venueUpdateSuccess = await _updateVenue(venueId, _selectedLocation!);
      
      setState(() {
        _isUpdatingVenue = false;
      });
      
      if (!venueUpdateSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Warning: Event location may not be fully updated")),
        );
        // You can decide whether to continue with the event update or not
      }
    }

        // Handle category_id
        String categoryId = _getCategoryIdFromEventType(_selectedEventType) ?? 
         widget.initialData['category_id'];

      print("New venue id: $venueId");
      print("New category id: $categoryId");



    // Sanitize ticket data: remove 'color' property if present
    List<Map<String, dynamic>> sanitizedTickets = _selectedTickets.map((ticket) {
      final sanitized = Map<String, dynamic>.from(ticket);
      sanitized.remove('color');
      return sanitized;
    }).toList();

    // Get the existing pricing from initialData, if available.
    final Map<String, dynamic> existingPricing = widget.initialData['pricing'] != null 
        ? Map<String, dynamic>.from(widget.initialData['pricing']) 
        : {};

    Map<String, dynamic> pricing = {};
    Map<String, dynamic> ticketAvailability = {};
    for (var ticket in sanitizedTickets) {
      String type = ticket['type'].toString().toLowerCase();
      // If a new price was provided, use it; otherwise, fall back to the existing price.
      pricing[type] = ticket['price'] ?? existingPricing[type] ?? 0;
      ticketAvailability[type] = ticket['quantity'];
    }

    // String? logoUrl;
    // if (_organizerLogoFile != null) {
    //   logoUrl = await _uploadLogoToCloudinary(_organizerLogoFile!);
    // }


      // Handle image uploads
    String? posterImageUrl = _existingPosterUrl ?? widget.initialData['image_url'];
    String? posterPublicId = widget.initialData['poster_public_id'];

    if (_selectedImage != null) {
      // If there's an existing public_id, attempt to update the image
    if (posterPublicId != null) {
      Map<String, String>? updatedImage = await _updateCloudinaryImage(
        publicId: posterPublicId, 
        imageFile: _selectedImage!
      );

      if (updatedImage != null) {
        posterImageUrl = updatedImage['secure_url'];
        posterPublicId = updatedImage['public_id'];
      }
    } else {
      // If no existing public_id, upload as new
      Map<String, String>? newImage = await uploadImageToCloudinary(_selectedImage!);
      if (newImage != null) {
        posterImageUrl = newImage['secure_url'];
        posterPublicId = newImage['public_id'];
      }
    }
  }

    String? logoUrl = _existingLogoUrl ?? widget.initialData['organizer_logo_url'];
    String? organizerPublicId = widget.initialData['organizer_public_id'];

      Map<String, String>? newLogoData;
    if (_organizerLogoFile != null) {
      newLogoData = await uploadImageToCloudinary(_organizerLogoFile!);
      if (newLogoData != null) {
        logoUrl = newLogoData['secure_url'];
        organizerPublicId = newLogoData['public_id'];
      }
    }

     // Format dates
    String? startDateStr = _startDate != null ? _startDate!.toIso8601String() : 
                         widget.initialData['start_date'];
   String? endDateStr = _endDate != null ? _endDate!.toIso8601String() : 
                       widget.initialData['end_date'];

    // String? timeRangeStr;
    // if (_startTime != null && _endTime != null) {
    //   // When user has edited the time, use the new values.
    //   timeRangeStr = "${_startTime!.format(context)} - ${_endTime!.format(context)}";
    // } else if (widget.initialData['time_range'] != null) {
    //   // Otherwise, if the initial data contains a non-null time_range, use it.
    //   timeRangeStr = widget.initialData['time_range'];
    // } else {
    //   // If both are missing, set a default value.
    //   timeRangeStr = null; // Change this to a value that makes sense for your app.
    // }

     final Map<String, dynamic> eventData = {
      "title": _eventNameController.text,
      "description": _descriptionController.text,
      "location": _locationController.text,
      "venue_id": venueId,
      "category_id": categoryId,
      "start_date": startDateStr,
      "end_date": endDateStr,
      // "time_range": timeRangeStr,
      "pricing": pricing,
      "ticket_availability": ticketAvailability,
      "image_url": posterImageUrl,
      "poster_public_id": posterPublicId,
      if (logoUrl != null) "organizer_logo_url": logoUrl,
      "organizer_email": _organizerEmailController.text,
      "organizer_public_id": organizerPublicId,
      // Preserve other fields from initialData
      "early_bird_enabled": widget.initialData['early_bird_enabled'],
      "early_bird_deadline": widget.initialData['early_bird_deadline'],
      "ticket_sale_start": widget.initialData['ticket_sale_start'],
      "ticket_sale_end": widget.initialData['ticket_sale_end'],
      "status": widget.initialData['status'],
    };

    print("📤 Sending update data: ${jsonEncode(eventData)}");

    try {
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "x-api-key":
              "d28233ab4f263d65184ff7803dc8d93e22fee9e02ecce07956f9edfd7c2e044a",
        },
        body: jsonEncode(eventData),
      );

      // Check if the widget is still mounted before using the context
      if (!mounted) return;

      if (response.statusCode == 200) {
        print("✅ Event updated successfully!");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Event updated successfully!")),
        );
        await _refreshEventData(); // Refresh the local data from the backend
        Navigator.pop(context, true);
      } else {
        print("❌ Error: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update event: ${response.body}")),
        );
      }
    } catch (error) {
      print("❌ Network Error: $error");
      // if (!mounted) return;
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text("Network error. Please try again.")),
      // );
    }
  }

  Future<Map<String, String>?> _updateCloudinaryImage({
  required String publicId,
  required File imageFile,
}) async {
  final String cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  final String apiKey = dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  final String apiSecret = dotenv.env['CLOUDINARY_API_SECRET'] ?? '';

  if (cloudName.isEmpty || apiKey.isEmpty || apiSecret.isEmpty) {
    print("Cloudinary configuration is missing.");
    return null;
  }

  final Uri url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/upload');

  final int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  // Build a string to sign that includes the public ID and timestamp.
  final String toSign = 'public_id=$publicId&timestamp=$timestamp$apiSecret';
  final String signature = sha1.convert(utf8.encode(toSign)).toString();

  var request = http.MultipartRequest('POST', url);
  request.fields['api_key'] = apiKey;
  request.fields['timestamp'] = timestamp.toString();
  request.fields['signature'] = signature;
  request.fields['public_id'] = publicId;
  request.fields['overwrite'] = 'true';

  request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

  try {
    var response = await request.send();
    if (response.statusCode == 200) {
      final resStream = await http.Response.fromStream(response);
      final Map<String, dynamic> data = jsonDecode(resStream.body);
      print("Cloudinary update successful: ${data['secure_url']}");
      return {
        'secure_url': data['secure_url'],
        'public_id': data['public_id']
      };
    } else {
      print("Cloudinary update failed with status: ${response.statusCode}");
      return null;
    }
  } catch (error) {
    print("Cloudinary update error: $error");
    return null;
  }
}

  //Function for updating the venue table based on venue_id

Future<bool> _updateVenue(String venueId, Map<String, dynamic> locationData) async {
  final url = Uri.parse("https://backendcode-production-6e08.up.railway.app/api/venues/${venueId}");
  
  // Prepare venue update data
  final venueUpdateData = {
    "name": locationData['name'] ?? _locationController.text,
    "address": locationData['address'] ?? _locationController.text,
    "city": "Nairobi", // You can make this dynamic if needed
    "country": "Kenya",
    "latitude": locationData['latitude'],
    "longitude": locationData['longitude'],
    "google_place_id": locationData['placeId'],
    // Keep other fields as is, or update them if you have the data
    // "capacity": "500",
    // "description": existing description,
    // "amenities": existing amenities,
    // "contact_info": existing contact info,
    // "is_active": true
  };
  
  print("📍 Updating venue with ID: ${venueId}");
  print("📤 Venue update data: ${jsonEncode(venueUpdateData)}");
  
  try {
    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "x-api-key": "d28233ab4f263d65184ff7803dc8d93e22fee9e02ecce07956f9edfd7c2e044a",
      },
      body: jsonEncode(venueUpdateData),
    );

    if (response.statusCode == 200) {
      print("✅ Venue updated successfully!");
      return true;
    } else {
      print("❌ Failed to update venue: ${response.body}");
      return false;
    }
  } catch (e) {
    print("❌ Error updating venue: $e");
    return false;
  }
}

// Add this function to map event type to category ID
String _getCategoryIdFromEventType(String? eventType) {
  // If event type hasn't changed, return the original category_id
  if (eventType == null || eventType.isEmpty) {
    return widget.initialData['category_id'];
  }
  
  // Map event type names to actual valid UUIDs from your backend
  Map<String, String> categoryMap = {
    'Sports': '9b5d881e-7366-41e8-a141-b6819c810271',
    'Concerts': 'f33fbe5c-ad17-4eef-aca6-70104270459b', 
    'Theater': 'fa06def7-a366-40d2-b362-1d7c898bf495',  
    'Family & Kids': '7250b16d-ad3f-4373-aaea-3d0e9d560889',
    'Art & Exhibitions': 'cee56953-a3fb-48f5-bfb9-3ffd4e611b16',
    'Comedy': '0d74cb47-22b7-4022-8149-1603a7775179',
    'Movies & Films': '748ae935-795f-4d9f-b605-1ceec9245b5e',
    'Festivals': 'd9e98234-44a1-498b-a44f-7aa780d6632f',
    'Education & Workshops': '89a91fab-66c5-476f-91ff-2805b2f0830a',
  };
  
  return categoryMap[eventType] ?? widget.initialData['category_id'];
}


    Future<void> _refreshEventData() async {
  final url = Uri.parse("https://backendcode-production-6e08.up.railway.app/api/events/${widget.eventId}");
  final response = await http.get(url, headers: {
    "x-api-key": "d28233ab4f263d65184ff7803dc8d93e22fee9e02ecce07956f9edfd7c2e044a",
  });
  if (response.statusCode == 200) {
    final updatedData = jsonDecode(response.body);
    setState(() {
      // Update your controllers and state variables based on updatedData.
      _eventNameController.text = updatedData['title'];
      _descriptionController.text = updatedData['description'];
      _locationController.text = updatedData['location'];
      // Update dates and times as needed.
    });
  } else {
    print("❌ Failed to refresh event data: ${response.body}");
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

  Future<String?> _uploadLogoToCloudinary(File logoFile) async {
    final String cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
    final String uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      print("Cloudinary configuration is missing.");
      return null;
    }

    final Uri url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/upload');

    var request = http.MultipartRequest('POST', url);
    request.fields['upload_preset'] = uploadPreset;
    request.files.add(await http.MultipartFile.fromPath('file', logoFile.path));

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        final resStream = await http.Response.fromStream(response);
        final Map<String, dynamic> data = jsonDecode(resStream.body);
        return data['secure_url'];
      } else {
        print("Cloudinary upload failed: ${response.statusCode}");
        return null;
      }
    } catch (error) {
      print("Cloudinary upload error: $error");
      return null;
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

              Widget _buildDateTimePickerField({
              required String label,
              required DateTime? selectedDateTime,
              required Function(DateTime) onDateTimeSelected,
            }) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (selectedDateTime != null) 
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display the label above the date field
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            // Customize the style as needed
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  DateFormat('MMM dd, yyyy hh:mm a').format(selectedDateTime),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                 IconButton(
                                  onPressed: () => _pickDateTime(context, onDateTimeSelected, selectedDateTime),
                                  icon: const Icon(Icons.edit, color: Colors.black),
                                ),

                                  // IconButton(
                                  //   onPressed: () => onDateTimeSelected(DateTime(0)),
                                  //   icon: const Icon(Icons.delete, color: Colors.black),
                                  // ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    DateTimePickerField(
                      label: label,
                      onDateTimeSelected: onDateTimeSelected,
                    ),
                ],
              );
            }

            Future<void> _pickDateTime(
            BuildContext context,
            Function(DateTime) onDateTimeSelected,
            DateTime? initialDateTime,
          ) async {
            BottomPicker.dateTime(
              pickerTitle: const Text(
                'Select Date & Time',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              initialDateTime: initialDateTime ?? DateTime.now(),
              minDateTime: DateTime.now(),  // or any custom minimum
              maxDateTime: DateTime.now().add(const Duration(days: 365)), // or any custom maximum
             onSubmit: (dynamic date) {
              if (date is DateTime) {
                onDateTimeSelected(date);
              }
            },
              onCloseButtonPressed: () {
                Navigator.pop(context); // Closes the BottomPicker
              },
              // Optional: You can style the bottom picker with gradients, button texts, etc.
              gradientColors: const [
                Color(0xff35D0C6),
                Color(0xffF1A377),
              ],
              closeIconColor: Colors.black, // Example styling
            ).show(context);
          }
                // Logo Upload Widget
              Widget _buildLogoUploadWidget() {
                return DottedBorder(
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
                    child: _buildLogoContent(),
                  ),
                );
              }

              Widget _buildLogoContent() {
                // Show new file if selected
                if (_organizerLogoFile != null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _organizerLogoFile!,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _organizerLogoFile!.path.split('/').last,
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
                                icon: const Icon(Icons.edit, color: Colors.black),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _organizerLogoFile = null;
                                  });
                                },
                                icon: const Icon(Icons.delete, color: Colors.black),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  );
                }
                
                // Show existing logo if available
                if (_existingLogoUrl != null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _existingLogoUrl!,
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / 
                                          loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 100,
                                  width: double.infinity,
                                  color: Colors.grey[200],
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.error_outline, color: Colors.red),
                                      SizedBox(height: 8),
                                      Text('Failed to load image'),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: _pickLogoImage,
                                  icon: _buildIconButton(Icons.edit),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _existingLogoUrl = null;
                                    });
                                  },
                                  icon: _buildIconButton(Icons.delete),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }
                
                // Show upload button if no image
                return Row(
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Choose file',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                );
              }

              // Poster Upload Widget
              Widget _buildPosterUploadWidget() {
                return DottedBorder(
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
                    child: _buildPosterContent(),
                  ),
                );
              }

              Widget _buildPosterContent() {
                // Show new image if selected
                if (_selectedImage != null) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.fitHeight,
                        ),
                      ),
                      _buildImageOverlayButtons(
                        onEdit: _pickPosterImage,
                        onDelete: () {
                          setState(() {
                            _selectedImage = null;
                          });
                        },
                      ),
                    ],
                  );
                }

                // Show existing poster if available
                if (_existingPosterUrl != null) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _existingPosterUrl!,
                          fit: BoxFit.fitHeight,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / 
                                      loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red),
                                  SizedBox(height: 8),
                                  Text('Failed to load image'),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      _buildImageOverlayButtons(
                        onEdit: _pickPosterImage,
                        onDelete: () {
                          setState(() {
                            _existingPosterUrl = null;
                          });
                        },
                      ),
                    ],
                  );
                }

                // Show upload placeholder if no image
                return GestureDetector(
                  onTap: _pickPosterImage,
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
                );
              }

              // Helper widget for overlay buttons
              Widget _buildImageOverlayButtons({
                required VoidCallback onEdit,
                required VoidCallback onDelete,
              }) {
                return Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: onEdit,
                        icon: _buildIconButton(Icons.edit),
                      ),
                      IconButton(
                        onPressed: onDelete,
                        icon: _buildIconButton(Icons.delete),
                      ),
                    ],
                  ),
                );
              }

              // Helper widget for icon buttons
              Widget _buildIconButton(IconData icon) {
                return Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                );
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
                Navigator.pop(context, true);
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
                  // Organizer Logo Upload Section
                  _buildLogoUploadWidget(),
                  const SizedBox(height: 24),
                  // Poster Upload Section
                  _buildPosterUploadWidget(),
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
               _buildDateTimePickerField(
                label: "Set Start Date & Time",
                selectedDateTime: _startDate,
                onDateTimeSelected: (newDateTime) {
                  setState(() {
                    _startDate = newDateTime;
                  });
                },
              ),
                  const SizedBox(height: 24),
                  // Event End Date
                 _buildDateTimePickerField(
                  label: "Set End Date & Time",
                  selectedDateTime: _endDate,
                  onDateTimeSelected: (dateTime) {
                    setState(() {
                      _endDate = dateTime;
                    });
                  },
                ),
                  const SizedBox(height: 24),
                  // Location
            FormInputFieldLocationWithEdit(
            title: 'Location',
            hintText: 'Enter event location',
            controller: _locationController,
            venueId: widget.initialData['venue_id'], // Use venue_id from initialData
            onPlaceSelected: (locationData) {
              setState(() {
                _selectedLocation = locationData;
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
                     ...List.generate(_selectedTickets.length, (index) {
                      final ticket = _selectedTickets[index];
                      return GestureDetector(
                        onTap: () => _editTicket(index), // New method to edit ticket
                        child: TicketTypeItem(
                          type: ticket['type'],
                          quantity: ticket['quantity'].toString(),
                          onDelete: () {
                            setState(() {
                              _selectedTickets.removeAt(index);
                            });
                          },
                        ),
                      );
                    }),
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
                  const SizedBox(height: 240),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
