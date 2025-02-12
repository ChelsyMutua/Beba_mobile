import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CustomLocationField extends StatefulWidget {
  final TextEditingController controller;
  final Function(Map<String, dynamic>)? onPlaceSelected;
  final String? label;
  final String hintText;

  const CustomLocationField({
    Key? key,
    required this.controller,
    this.onPlaceSelected,
    this.label = "Location",
    this.hintText = 'Enter location',
  }) : super(key: key);

  @override
  _CustomLocationFieldState createState() => _CustomLocationFieldState();
}

class _CustomLocationFieldState extends State<CustomLocationField> {
  late final GoogleMapsPlaces _places;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    _places = GoogleMapsPlaces(apiKey: apiKey);
  }

  Future<List<Prediction>> _getSuggestions(String pattern) async {
    if (pattern.isEmpty) return [];
    
    setState(() => _isLoading = true);
    
    try {
      final response = await _places.autocomplete(
        pattern,
        types: ['address', 'establishment'],
        components: [Component(Component.country, "us")],
      );
      
      debugPrint('Autocomplete response status: ${response.status}');
      
      if (!response.isOkay) {
        debugPrint('Error in autocomplete: ${response.errorMessage}');
        return [];
      }
      
      debugPrint('Received ${response.predictions.length} predictions');
      return response.predictions;
    } catch (e) {
      debugPrint('Error fetching suggestions: $e');
      return [];
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
        ],
        TypeAheadField<Prediction>(
          suggestionsCallback: _getSuggestions,
          builder: (context, controller, focusNode) {
            return TextField(
              controller: widget.controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: widget.hintText,
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : null,
              ),
            );
          },
          itemBuilder: (context, Prediction suggestion) {
            return ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(
                suggestion.structuredFormatting?.mainText ?? suggestion.description ?? '',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                suggestion.structuredFormatting?.secondaryText ?? '',
                style: TextStyle(color: Colors.grey[600]),
              ),
            );
          },
          onSelected: (Prediction suggestion) async {
            try {
              final detailsResponse = await _places.getDetailsByPlaceId(
                suggestion.placeId ?? '',
              );
              
              if (detailsResponse.isOkay) {
                final result = detailsResponse.result;
                widget.controller.text = result.formattedAddress ?? 
                    suggestion.description ?? '';

                if (widget.onPlaceSelected != null) {
                  widget.onPlaceSelected!({
                    'placeId': suggestion.placeId,
                    'name': result.name,
                    'address': result.formattedAddress ?? suggestion.description,
                    'latitude': result.geometry?.location.lat,
                    'longitude': result.geometry?.location.lng,
                  });
                }
              } else {
                widget.controller.text = suggestion.description ?? '';
                
                if (widget.onPlaceSelected != null) {
                  widget.onPlaceSelected!({
                    'placeId': suggestion.placeId,
                    'name': suggestion.description,
                    'address': suggestion.description,
                  });
                }
              }
            } catch (e) {
              debugPrint('Error fetching place details: $e');
              widget.controller.text = suggestion.description ?? '';
            }
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _places.dispose();
    super.dispose();
  }
}