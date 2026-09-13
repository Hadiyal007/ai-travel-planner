class Destination {
  final String name;
  final String country;
  final String imageUrl;
  final String tagline;

  const Destination({
    required this.name,
    required this.country,
    required this.imageUrl,
    required this.tagline,
  });

  factory Destination.fromMap(Map<String, dynamic> map) {
    return Destination(
      name: map['name'] ?? '',
      country: map['country'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      tagline: map['tagline'] ?? '',
    );
  }
}