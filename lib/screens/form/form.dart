import 'dart:io';

import 'package:beba_mobile/components/app_bar.dart';
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
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

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
    'Conference',
    'Concert',
    'Workshop',
    'Exhibition',
    'Other'
  ];

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
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // Implement form submission
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
            'Create Event',
            style: TextStyle(
              fontSize: 16,
              // fontWeight: FontWeight.bold,
              color: Colors.black
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

                DateTimePickerField(
                onDateTimeSelected: (dateTime) {
                  setState(() {
                    _startDate = dateTime;
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
                      // Handle the selected location data
                      print('Selected location: $locationData');
                      // You can access:
                      // locationData['placeId']
                      // locationData['name']
                      // locationData['address']
                      // locationData['latitude']
                      // locationData['longitude']
                    },
                ),

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
                        _selectedTickets.remove(ticket); // Remove from parent state
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
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

  const DateTimePickerField({Key? key, required this.onDateTimeSelected}) : super(key: key);

  @override
  _DateTimePickerFieldState createState() => _DateTimePickerFieldState();
}

class _DateTimePickerFieldState extends State<DateTimePickerField> {
  DateTime? _selectedDateTime;

  void _pickDateTime(BuildContext context) {
    BottomPicker.dateTime(
      pickerTitle: Text("Set the event exact time and date"),
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
      maxDateTime: DateTime.now().add(const Duration(days: 365)), // Maximum 1 year ahead
      gradientColors: const [
        Color(0xfffdcbf1),
        Color(0xffe6dee9),
      ],
    ).show(context);
  }

  

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        const Text(
          "Set Date & Time",
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
                      : DateFormat("EEEE, d MMMM yyyy HH:mm").format(_selectedDateTime!),
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

  const FormInputFieldLocation({
    Key? key,
    required this.title,
    required this.hintText,
    required this.controller,
    this.onPlaceSelected,
  }) : super(key: key);

  @override
  State<FormInputFieldLocation> createState() => _FormInputFieldLocationState();
}

class _FormInputFieldLocationState extends State<FormInputFieldLocation> {
  GoogleMapController? mapController;
  // PlacesDetailsResponse? placeDetail;

  @override
  Widget build(BuildContext context) {
  final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Text(widget.title),
        const SizedBox(height: 8),
        GooglePlaceAutoCompleteTextField(
          textEditingController: widget.controller,
          googleAPIKey: apiKey,
          inputDecoration: InputDecoration(
            hintText: widget.hintText,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          debounceTime: 800,
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
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
