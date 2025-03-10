class Event {
  final String id;
  final String title;
  final String description;
  final DateTime? startDate;         // corresponds to "date" in your backend
  final DateTime? endDate; 
  final String? time;           // or parse this into a TimeOfDay if needed
  final String? venueId;
  final String? categoryId;
  final Map<String, dynamic>? pricing;
  final Map<String, dynamic>? ticketAvailability;
  final DateTime? earlyBirdDeadline;
  final bool? earlyBirdEnabled;
  final DateTime ticketSaleStart;
  final DateTime? ticketSaleEnd;
  final String status;
  final String? imageUrl;
  final String? organizerLogo;
  final String? slug;
  final String? posterPublicId; 
  final String? organizerPublicId;   
  final DateTime createdAt;
  final DateTime updatedAt;

  Event({
    required this.id,
    required this.title,
    required this.description,
    this.startDate,
    this.endDate,
    this.time,
    this.venueId,
    this.categoryId,
    this.pricing,
    this.ticketAvailability,
    this.earlyBirdDeadline,
    this.earlyBirdEnabled,
    required this.ticketSaleStart,
    this.ticketSaleEnd,
    required this.status,
    this.imageUrl,
    this.organizerLogo,
    this.slug,
    this.posterPublicId,
    this.organizerPublicId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      time: json['time'] as String?,
      venueId: json['venue_id'] as String?,
      categoryId: json['category_id'] as String?,
      pricing: json['pricing'] as Map<String, dynamic>?,
      ticketAvailability: json['ticket_availability'] as Map<String, dynamic>?,
      earlyBirdDeadline: json['early_bird_deadline'] != null
          ? DateTime.parse(json['early_bird_deadline'])
          : null,
      earlyBirdEnabled: json['early_bird_enabled'] as bool?,
      ticketSaleStart: DateTime.parse(json['ticket_sale_start']),
      ticketSaleEnd: json['ticket_sale_end'] != null
          ? DateTime.parse(json['ticket_sale_end'])
          : null,
      status: json['status'] as String,
      imageUrl: json['image_url'] as String?,
      organizerLogo: json['organizer_logo_url'] as String?,
      slug: json['slug'] as String?,
      posterPublicId: json['poster_public_id'] as String?,
      organizerPublicId: json['organizer_public_id'] as String?,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'time': time,
      'venue_id': venueId,
      'category_id': categoryId,
      'pricing': pricing,
      'ticket_availability': ticketAvailability,
      'early_bird_deadline': earlyBirdDeadline?.toIso8601String(),
      'early_bird_enabled': earlyBirdEnabled,
      'ticket_sale_start': ticketSaleStart.toIso8601String(),
      'ticket_sale_end': ticketSaleEnd?.toIso8601String(),
      'status': status,
      'image_url': imageUrl,
      'organizer_logo_url': organizerLogo,
      'slug': slug,
      'poster_public_id': posterPublicId,
      'organizer_public_id': organizerPublicId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
