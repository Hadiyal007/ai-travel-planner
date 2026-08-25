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
}

/// Temporary mock data — replaced by a real Places API call in Phase 8.
const List<Destination> mockDestinations = [
  Destination(
    name: 'Goa',
    country: 'India',
    imageUrl: 'https://images.unsplash.com/photo-1512343879784-a960bf40e7f2',
    tagline: 'Beaches, nightlife & seafood',
  ),
  Destination(
    name: 'Manali',
    country: 'India',
    imageUrl: 'https://images.unsplash.com/photo-1626621341517-bbf3d9990a23',
    tagline: 'Mountains & adventure',
  ),
  Destination(
    name: 'Jaipur',
    country: 'India',
    imageUrl: 'https://images.unsplash.com/photo-1599661046289-e31897846e41',
    tagline: 'Forts, palaces & culture',
  ),
];