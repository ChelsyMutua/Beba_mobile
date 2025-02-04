import 'package:flutter/material.dart';
import 'package:wheel_slider/wheel_slider.dart';

class TicketSelector extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onTicketsSelected;

  const TicketSelector({Key? key, required this.onTicketsSelected}) : super(key: key);

  @override
  _TicketSelectorState createState() => _TicketSelectorState();
}

class _TicketSelectorState extends State<TicketSelector> {
  Map<String, dynamic>? selectedType;
  int quantity = 0;
  String pricePerTicket = '';
  final List<Map<String, dynamic>> selectedTickets = [];
  final Set<String> _disabledTicketTypes = {}; // Track selected ticket types
  final TextEditingController _priceController = TextEditingController();

  final List<Map<String, dynamic>> ticketTypes = [
    {'id': 1, 'name': 'Regular', 'color': Colors.pinkAccent},
    {'id': 2, 'name': 'VIP', 'color': Colors.greenAccent},
    {'id': 3, 'name': 'VVIP', 'color': Colors.blueAccent},
    {'id': 4, 'name': 'Student', 'color': Colors.purpleAccent},
    {'id': 5, 'name': 'Early Bird', 'color': Colors.amberAccent},
  ];

  void handleTypeSelect(Map<String, dynamic> type) {
    setState(() {
      selectedType = type;
    });
  }

  void handleQuantityChange(int increment) {
    setState(() {
      quantity = (quantity + increment).clamp(0, 99);
    });
  }

  void handlePriceChange(String value) {
    setState(() {
      pricePerTicket = value.replaceAll(RegExp(r'[^0-9]'), '');
    });
  }

  void handleConfirm() {
    if (selectedType != null && quantity > 0 && pricePerTicket.isNotEmpty) {
      setState(() {
        // Store the selected ticket and prevent re-selection
        selectedTickets.add({
          'id': DateTime.now().millisecondsSinceEpoch,
          'type': selectedType!['name'],
          'quantity': quantity,
          'price': int.parse(pricePerTicket),
          'color': selectedType!['color'],
          'total': quantity * int.parse(pricePerTicket),
        });

        _disabledTicketTypes.add(selectedType!['name']); // Disable re-selection

        // Reset selections
        selectedType = null;
        quantity = 0;
        pricePerTicket = '';
        _priceController.clear();
      });

      // Optionally show feedback
     ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(
      'Ticket added successfully!',
      style: TextStyle(
        color: Colors.white, // Text color remains white for contrast
      ),
    ),
    backgroundColor: Color(0xFFFAA173), 
  ),
);


      // Removed the callback to prevent closing the dialog
      // widget.onTicketsSelected(List.from(selectedTickets));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with Close Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Ticket Type',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(selectedTickets),
                  ),
                ],
              ),
            ),

            // Main Content
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        children: ticketTypes.map((type) {
                          bool isDisabled = _disabledTicketTypes.contains(type['name']);

                          return ChoiceChip(
                            label: Text(type['name']),
                            selected: selectedType?['id'] == type['id'],
                            selectedColor: type['color'].withOpacity(0.3),
                            onSelected: isDisabled ? null : (selected) => handleTypeSelect(type),
                            backgroundColor: isDisabled ? Colors.grey.shade300 : null,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Quantity Selector
                      const Text("Select Quantity", style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                     Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: WheelSlider.number(
                            horizontal: false,
                            verticalListHeight: 250.0,
                            perspective: 0.01,
                            // The maximum count for your slider; you mentioned 99 as your clamp:
                            totalCount: 20000,
                            // The initial value, tied to your existing quantity state:
                            initValue: quantity,
                            // Style for non-selected numbers
                            unSelectedNumberStyle: const TextStyle(
                              fontSize: 18.0,
                              color: Colors.black54,
                            ),
                            // Keep the slider’s current index in sync with `quantity`
                            currentIndex: quantity,
                            // When the wheel changes, update the `quantity` in State
                            onValueChanged: (val) {
                              setState(() {
                                quantity = val;
                              });
                            },
                            // Optional haptic feedback when the wheel moves
                            hapticFeedbackType: HapticFeedbackType.heavyImpact,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Price Input
                      const Text("Price Per Ticket (Ksh)", style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        onChanged: handlePriceChange,
                        decoration: InputDecoration(
                          hintText: "Enter amount",
                          prefixText: "Ksh ",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Total Price
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total", style: TextStyle(fontSize: 18)),
                            Text(
                              "Ksh ${quantity * (int.tryParse(pricePerTicket) ?? 0)}",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Confirm Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFF01DCDC),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: handleConfirm,
                          child: const Text("Confirm", style: TextStyle(color: Colors.black)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
