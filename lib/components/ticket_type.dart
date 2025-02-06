import 'package:flutter/material.dart';
import 'package:wheel_slider/wheel_slider.dart';

class TicketSelector extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onTicketsSelected;

  const TicketSelector({Key? key, required this.onTicketsSelected})
      : super(key: key);

  @override
  _TicketSelectorState createState() => _TicketSelectorState();
}

class _TicketSelectorState extends State<TicketSelector> {
  Map<String, dynamic>? selectedType;
  int quantity = 0;
  String pricePerTicket = '';
  final List<Map<String, dynamic>> selectedTickets = [];
  final Set<String> _disabledTicketTypes = {};
  final TextEditingController _priceController = TextEditingController();

  final List<Map<String, dynamic>> ticketTypes = [
    {'id': 1, 'name': 'Regular', 'color': Colors.pinkAccent},
    {'id': 2, 'name': 'VIP', 'color': Colors.greenAccent},
    {'id': 3, 'name': 'VVIP', 'color': Colors.blueAccent},
    {'id': 4, 'name': 'Student', 'color': Colors.purpleAccent},
    {'id': 5, 'name': 'Early Bird', 'color': Colors.amberAccent},
    {'id': 6, 'name': 'Free', 'color': Colors.redAccent},
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
    if (selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a ticket type first.')),
      );
      return;
    }

    bool isFree = selectedType!['name'] == 'Free';

    // Validate quantity (for both free & paid tickets)
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid quantity.')),
      );
      return;
    }

    // If not free, validate price
    if (!isFree && (pricePerTicket.isEmpty || int.tryParse(pricePerTicket) == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid ticket price.')),
      );
      return;
    }

    setState(() {
      // Calculate the price (0 if free)
      final parsedPrice = isFree ? 0 : int.parse(pricePerTicket);
      final totalPrice = quantity * parsedPrice;

      selectedTickets.add({
        'id': DateTime.now().millisecondsSinceEpoch,
        'type': selectedType!['name'],
        'quantity': quantity,
        'price': parsedPrice,
        'color': selectedType!['color'],
        'total': totalPrice,
      });

      // Disable this ticket type from being selected again
      _disabledTicketTypes.add(selectedType!['name']);

      // Reset form
      selectedType = null;
      quantity = 0;
      pricePerTicket = '';
      _priceController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ticket added successfully!'),
        backgroundColor: Color(0xFFFAA173),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isFree = selectedType != null && selectedType!['name'] == 'Free';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
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
                      // Ticket Types
                      Wrap(
                        spacing: 8,
                        children: ticketTypes.map((type) {
                          bool isDisabled = _disabledTicketTypes.contains(type['name']);
                          return ChoiceChip(
                            label: Text(type['name']),
                            selected: selectedType?['id'] == type['id'],
                            selectedColor: type['color'].withOpacity(0.3),
                            onSelected: isDisabled
                                ? null
                                : (selected) => handleTypeSelect(type),
                            backgroundColor: isDisabled ? Colors.grey.shade300 : null,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // ALWAYS show quantity (free or paid)
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
                            totalCount: 200, // you can adjust this or keep it large
                            initValue: quantity,
                            unSelectedNumberStyle: const TextStyle(
                              fontSize: 16.0,
                              color: Colors.black54,
                            ),
                            currentIndex: quantity,
                            onValueChanged: (val) {
                              setState(() {
                                quantity = val;
                              });
                            },
                            hapticFeedbackType: HapticFeedbackType.heavyImpact,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Show PRICE + TOTAL only if NOT free
                      if (!isFree) ...[
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
                      ],

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
                          child: const Text(
                            "Confirm",
                            style: TextStyle(color: Colors.black),
                          ),
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
