class TicketModel {
  final String type;
  final int quantity;
  final double price;

  TicketModel({
    required this.type, 
    required this.quantity, 
    required this.price
  });

  // Factory constructor to extract from database JSON
  factory TicketModel.fromJson(Map<String, dynamic> json, String ticketType) {
    return TicketModel(
      type: ticketType,
      quantity: json['ticket_availability'][ticketType]['quantity'] ?? 0,
      price: json['pricing'][ticketType]['price'] ?? 0.0
    );
  }

  // Convert back to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'ticket_availability': {
        type: {'quantity': quantity}
      },
      'pricing': {
        type: {'price': price}
      }
    };
  }
}