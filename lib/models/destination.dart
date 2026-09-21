class Destination {
  final String name;
  final String country;
  final String imageUrl;
  final String tagline;
  final String description;
  final List<String> galleryImages;

  const Destination({
    required this.name,
    required this.country,
    required this.imageUrl,
    required this.tagline,
    required this.description,
    this.galleryImages = const [],
  });

  factory Destination.fromMap(Map<String, dynamic> map) {
    return Destination(
      name: map['name'] ?? '',
      country: map['country'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      tagline: map['tagline'] ?? '',
      description: map['description'] ?? '',
      galleryImages: (map['galleryImages'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}