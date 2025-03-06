class Venue {
  final String id;
  final String name;

  Venue(
  {
  required this.id, 
  required this.name
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}
