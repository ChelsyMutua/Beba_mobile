import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

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

              // Replace the existing Date & Time Column with:
                  EventDateTimePicker(
                    startDate: _startDate,
                    startTime: _startTime,
                    endDate: _endDate,
                    endTime: _endTime,
                    onStartDateChanged: (date) => setState(() => _startDate = date),
                    onStartTimeChanged: (time) => setState(() => _startTime = time),
                    onEndDateChanged: (date) => setState(() => _endDate = date),
                    onEndTimeChanged: (time) => setState(() => _endTime = time),
                  ),

                const SizedBox(height: 24),

                // Location
                FormInputField(
                  title: 'Location',
                  hintText: 'Enter event location',
                  controller: _locationController,
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
                    ..._ticketTypes.map((ticket) => TicketTypeItem(
                          type: ticket['type'],
                          quantity: ticket['quantity'].toString(),
                          onDelete: () {
                            setState(() {
                              _ticketTypes.remove(ticket);
                            });
                          },
                        )),
                    TextButton(
                      onPressed: () {
                        _showAddTicketDialog(context);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '+ Add Ticket Type',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 150),
                // NOTE: The bottom button container was moved to floatingActionButton
                // but we did not remove it — we simply relocated it.
              ],
            ),
          ),
        ),
      ),
    
    ),
    );
  }

  void _showAddTicketDialog(BuildContext context) {
    String selectedType = _predefinedTicketTypes[0];
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Ticket Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedType,
              items: _predefinedTicketTypes.map((String type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (String? value) {
                if (value != null) {
                  selectedType = value;
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (quantityController.text.isNotEmpty) {
                int quantity = int.tryParse(quantityController.text) ?? 0;
                if (quantity > 0) {
                  setState(() {
                    _ticketTypes.add({'type': selectedType, 'quantity': quantity});
                  });
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
class EventDateTimePicker extends StatelessWidget {
  final DateTime? startDate;
  final TimeOfDay? startTime;
  final DateTime? endDate;
  final TimeOfDay? endTime;
  final Function(DateTime?) onStartDateChanged;
  final Function(TimeOfDay?) onStartTimeChanged;
  final Function(DateTime?) onEndDateChanged;
  final Function(TimeOfDay?) onEndTimeChanged;

  const EventDateTimePicker({
    Key? key,
    this.startDate,
    this.startTime,
    this.endDate,
    this.endTime,
    required this.onStartDateChanged,
    required this.onStartTimeChanged,
    required this.onEndDateChanged,
    required this.onEndTimeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Row(
          children: [
            Icon(Icons.calendar_today, size: 20, color: Colors.grey[700]),
            const SizedBox(width: 8),
            const Text(
              'Event date & time',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Start row
        _buildTimeRow(
          context: context,
          label: 'Starts',
          date: startDate,
          time: startTime,
          onDateChanged: onStartDateChanged,
          onTimeChanged: onStartTimeChanged,
          firstDate: DateTime.now(),
        ),
        const SizedBox(height: 12),

        // End row
        _buildTimeRow(
          context: context,
          label: 'Ends',
          date: endDate,
          time: endTime,
          onDateChanged: onEndDateChanged,
          onTimeChanged: onEndTimeChanged,
          firstDate: startDate ?? DateTime.now(),
        ),
      ],
    );
  }

  Widget _buildTimeRow({
    required BuildContext context,
    required String label,
    required DateTime? date,
    required TimeOfDay? time,
    required Function(DateTime?) onDateChanged,
    required Function(TimeOfDay?) onTimeChanged,
    required DateTime firstDate,
  }) {
    return Row(
      children: [
        // Label
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Date button
        Expanded(
          child: TextButton(
            onPressed: () async {
              final selectedDate = await showDatePicker(
                context: context,
                initialDate: date ?? firstDate,
                firstDate: firstDate,
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              onDateChanged(selectedDate);
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey[200],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              date == null
                  ? 'Date'
                  : DateFormat('MMM dd, yyyy').format(date),
              style: TextStyle(
                color: date == null ? Colors.black87 : Colors.blue[600],
                fontSize: 14,
                fontWeight: date == null ? FontWeight.normal : FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

      // Time button
      Expanded(
        child: TextButton(
          onPressed: () async {
            final selectedTime = await showTimePicker(
              context: context,
              initialTime: time ?? const TimeOfDay(hour: 9, minute: 0),
            );

            // Update only if user didn’t cancel
            if (selectedTime != null) {
              onTimeChanged(selectedTime);
            }
          },
          style: TextButton.styleFrom(
            backgroundColor: Colors.grey[200],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            time == null ? 'Time' : _formatTime(time),
            style: TextStyle(
              color: time == null ? Colors.black87 : Colors.blue[600],
              fontSize: 14,
              fontWeight: time == null ? FontWeight.normal : FontWeight.w500,
            ),
          ),
        ),
      ),
      ],
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
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
