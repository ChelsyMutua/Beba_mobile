import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:beba_mobile/models/venue.dart'; // Import the Venue model

class FormInputFieldLocationWithEdit extends StatefulWidget {
  final String title;
  final String hintText;
  final TextEditingController controller;
  final Function(Map<String, dynamic>)? onPlaceSelected;
  final String? venueId; // Optional: used to fetch the venue name

  const FormInputFieldLocationWithEdit({
    Key? key,
    required this.title,
    required this.hintText,
    required this.controller,
    this.onPlaceSelected,
    this.venueId,
  }) : super(key: key);

  @override
  _FormInputFieldLocationWithEditState createState() =>
      _FormInputFieldLocationWithEditState();
}

class _FormInputFieldLocationWithEditState
    extends State<FormInputFieldLocationWithEdit> {
  bool _isEditing = false;
  final FocusNode _focusNode = FocusNode();

  // Fetch the venue using the venueId.
  Future<Venue> fetchVenue(String venueId) async {
    final url = Uri.parse("https://backendcode-production-6e08.up.railway.app/api/venues/$venueId");
    final response = await http.get(url, headers: {
      "x-api-key": "d28233ab4f263d65184ff7803dc8d93e22fee9e02ecce07956f9edfd7c2e044a",
    });

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return Venue.fromJson(jsonData);
    } else {
      throw Exception("Failed to load venue");
    }
  }

  // Toggle editing mode.
  void _toggleEditing() {
    setState(() {
      _isEditing = true;
      widget.controller.clear();
      _focusNode.requestFocus();
    });
  }

  @override
void dispose() {
  _focusNode.dispose();
  super.dispose();
}


  // Helper method for building the display container.
  Widget _buildDisplayContainer(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

 @override
void initState() {
  super.initState();
  // If a venueId is provided, assume we have an existing venue to fetch.
  if (widget.venueId != null) {
    _isEditing = false;
  } else {
    _isEditing = widget.controller.text.isEmpty;
  }
}


  @override
  Widget build(BuildContext context) {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row with edit button.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            if (!_isEditing)
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: _toggleEditing,
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Either display the venue name or the auto-complete field.
        _isEditing
            ? GooglePlaceAutoCompleteTextField(
                textEditingController: widget.controller,
                focusNode: _focusNode,
                googleAPIKey: apiKey,
                inputDecoration: InputDecoration(
                  hintText: widget.hintText,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  final locationData = {
                    'placeId': prediction.placeId,
                    'name': prediction.description,
                    'address': prediction.description,
                    'latitude': prediction.lat,
                    'longitude': prediction.lng,
                  };
                  if (widget.onPlaceSelected != null) {
                    widget.onPlaceSelected!(locationData);
                  }
                  setState(() {
                    _isEditing = false;
                  });
                },
                itemClick: (Prediction prediction) {
                  widget.controller.text = prediction.description ?? '';
                  widget.controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: widget.controller.text.length),
                  );
                  final locationData = {
                    'name': prediction.description,
                    'address': prediction.description,
                    'placeId': prediction.placeId,
                  };
                  if (widget.onPlaceSelected != null) {
                    widget.onPlaceSelected!(locationData);
                  }
                  setState(() {
                    _isEditing = false;
                  });
                },
              )
            : (widget.venueId != null
                ? FutureBuilder<Venue>(
                    future: fetchVenue(widget.venueId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildDisplayContainer("Loading venue...");
                      } else if (snapshot.hasError) {
                        return _buildDisplayContainer("Error loading venue");
                      } else if (snapshot.hasData) {
                        if (widget.controller.text.isEmpty) {
                          widget.controller.text = snapshot.data!.name;
                        }
                        return _buildDisplayContainer(widget.controller.text);
                      } else {
                        return _buildDisplayContainer(widget.hintText);
                      }
                    },
                  )
                : _buildDisplayContainer(
                    widget.controller.text.isEmpty ? widget.hintText : widget.controller.text)),
      ],
    );
  }
}
