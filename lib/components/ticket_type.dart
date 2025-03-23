import 'package:flutter/material.dart';
import 'package:wheel_slider/wheel_slider.dart';

class TicketSelector extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onTicketsSelected;
  final VoidCallback? onCancel;
  final Map<String, dynamic>? initialTicket;
  

  const TicketSelector({Key? key, required this.onTicketsSelected, this.onCancel, this.initialTicket})
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
    {'id': 7, 'name': 'Advanced', 'color': Colors.tealAccent},
    {'id': 8, 'name': 'Group of 5', 'color': Colors.orangeAccent}, // 🧑‍🤝‍🧑 Group ticket with orange color
    {'id': 9, 'name': 'At Gate', 'color': Colors.indigoAccent}, 

  ];


@override
void initState() {
  super.initState();
  if (widget.initialTicket != null) {
    String initialType = widget.initialTicket!['type'].toString().toLowerCase();
    // Use firstWhere with an empty map as default
    Map<String, dynamic> matchingType = ticketTypes.firstWhere(
      (type) => type['name'].toString().toLowerCase() == initialType,
      orElse: () => <String, dynamic>{},
    );
    
    // Check if a matching ticket type was found.
    if (matchingType.isNotEmpty) {
      selectedType = matchingType;
    } else {
      selectedType = {'name': widget.initialTicket!['type']};
    }
    
    quantity = widget.initialTicket!['quantity'] ?? 0;
    pricePerTicket = widget.initialTicket!['price']?.toString() ?? '';
    _priceController.text = pricePerTicket;
    
    print("DEBUG: Prefilled ticket type: ${selectedType!['name']}");
    print("DEBUG: Prefilled quantity: $quantity");
    print("DEBUG: Prefilled price: $pricePerTicket");
  }
}



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

  // Validate quantity
  if (quantity <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select a valid quantity.')),
    );
    return;
  }

  // Validate price for non-free tickets
  if (!isFree && (pricePerTicket.isEmpty || int.tryParse(pricePerTicket) == null)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter a valid ticket price.')),
    );
    return;
  }

  final parsedPrice = isFree ? 0 : int.parse(pricePerTicket);
  final totalPrice = quantity * parsedPrice;

  // Create a ticket data map.
  // If editing, preserve the existing 'id', otherwise generate a new one.
  Map<String, dynamic> ticketData = {
    'id': widget.initialTicket != null
        ? widget.initialTicket!['id']
        : DateTime.now().millisecondsSinceEpoch,
    'type': selectedType!['name'],
    'quantity': quantity,
    'price': parsedPrice,
    'color': selectedType!['color'],
    'total': totalPrice,
  };

  // In edit mode, return the updated ticket.
  if (widget.initialTicket != null) {
    Navigator.of(context).pop([ticketData]); // Return as a list, matching onTicketsSelected's expectation.
  } else {
    // In add mode, add the new ticket to the list.
    selectedTickets.add(ticketData);
    Navigator.of(context).pop(selectedTickets);
  }
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
                   icon: Icon(Icons.close),
                   onPressed: () {
                     // Use the onCancel callback if provided
                     if (widget.onCancel != null) {
                       widget.onCancel!();
                     } else {
                       // Fallback to default close behavior
                       Navigator.of(context).pop(null);
                     }
                   },
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
                            totalCount: 50000, // you can adjust this or keep it large
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
                        child: Text(
                          widget.initialTicket != null ? "Update" : "Confirm",
                          style: const TextStyle(color: Colors.black),
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
