/// Seed content for the `popular_destinations` Firestore collection, used
/// once by [FirestoreService.seedPopularDestinations].
///
/// `imageUrl` here is a deterministic placeholder (picsum.photos, seeded
/// by destination name so it's stable and always loads) rather than a
/// hand-picked real photo of the place. Sourcing a verified, always-
/// working photo URL for every destination isn't something that can be
/// done reliably without a real risk of a broken/mismatched image, so
/// these are meant to be replaced with real photos per destination —
/// either manually (search, right-click a photo, "copy image address"),
/// or later via a proper photo API. The app already falls back to a
/// broken-image icon gracefully if a URL ever 404s, so this is a safe
/// starting point either way.
const List<Map<String, dynamic>> destinationSeedData = [
  // --- Gujarat ---
  {
    'name': 'Ahmedabad',
    'country': 'Gujarat, India',
    'tagline': "India's first UNESCO World Heritage City",
    'description':
    'A city of stepwells, Mughal-era gates, and the calm of Sabarmati Ashram. '
        'Wander the old city\'s pols (traditional neighbourhoods), see Sidi Saiyyed\'s '
        'carved stone lattice windows, and eat your way through Manek Chowk\'s night market.',
    'imageUrl': 'https://media.istockphoto.com/id/1322194536/photo/sabarmati-riverfront-aerial-view-ahmedabad.jpg?s=612x612&w=0&k=20&c=G8qSUp_FeJzB4Tq1vd02NGGSvUC-pI_PSb_z7ELdXAI=',
  },
  {
    'name': 'Vadodara',
    'country': 'Gujarat, India',
    'tagline': 'Palaces, gardens, and the Kala Ghoda of the west',
    'description':
    'Home to the grand Laxmi Vilas Palace — four times the size of Buckingham '
        'Palace — plus leafy university gardens, museums, and a laid-back, cultured pace.',
    'imageUrl': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/27/Baroda_3.jpg/500px-Baroda_3.jpg?utm_source=en.wikivoyage.org&utm_campaign=parser&utm_content=thumbnail',
  },
  {
    'name': 'Saputara',
    'country': 'Gujarat, India',
    'tagline': "Gujarat's only hill station",
    'description':
    'A cool-climate retreat in the Sahyadri hills, built around a lake with a '
        'cable-car ropeway, sunset viewpoints, tribal museums, and monsoon-green valleys.',
    'imageUrl': 'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/0f/48/7c/c9/sunset-point.jpg?w=1200&h=-1&s=1',
  },
  {
    'name': 'Rann of Kutch',
    'country': 'Gujarat, India',
    'tagline': 'A white salt desert under a full moon',
    'description':
    'The Great Rann turns into a blinding white salt flat every winter, hosting the '
        'Rann Utsav festival with tents, folk music, and handicrafts from the Kutchi villages nearby.',
    'imageUrl': 'https://s7ap1.scene7.com/is/image/incredibleindia/rann-of-kutch-kutch-gujarat-4-attr-hero?qlt=82&ts=1726734049517',
  },
  {
    'name': 'Diu',
    'country': 'Gujarat, India',
    'tagline': 'Portuguese forts and quiet beaches',
    'description':
    'A small island union territory with a 16th-century Portuguese fort, whitewashed '
        'churches, and some of western India\'s cleanest, calmest beaches.',
    'imageUrl': 'https://media.istockphoto.com/id/1268472719/photo/india.jpg?s=612x612&w=0&k=20&c=DdP4gE2z7R8u1bjTarTnEeTEx4ulRCXTQQ-W-FLxrx8=',
  },
  {
    'name': 'Dwarka',
    'country': 'Gujarat, India',
    'tagline': 'One of Hinduism\'s four holiest pilgrimage sites',
    'description':
    'Home to the towering Dwarkadhish Temple on the Arabian Sea coast, believed to mark '
        'the site of Krishna\'s ancient kingdom.',
    'imageUrl': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTMkVfBipOZ4xXWQFsNW_JTUI29cqXEjjFTgcj2ixke4ehETUtDCmla5uu3&s=10',
  },
  {
    'name': 'Somnath',
    'country': 'Gujarat, India',
    'tagline': 'The first among India\'s twelve Jyotirlinga shrines',
    'description':
    'A coastal temple town rebuilt many times over the centuries, with a dramatic '
        'sound-and-light show against the temple at night, right on the shoreline.',
    'imageUrl': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSb2U9J2rREtH9_IpsR5iV4EWw_O1ORJaITxpZi8zDFeh9dM13CXUwtKVwl&s=10',
  },
  {
    'name': 'Statue of Unity, Kevadia',
    'country': 'Gujarat, India',
    'tagline': 'The world\'s tallest statue',
    'description':
    'A 182-metre monument to Sardar Vallabhbhai Patel overlooking the Narmada dam, with '
        'a viewing gallery, valley-of-flowers park, and jungle safari nearby.',
    'imageUrl': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR1ig0oi7wYec1B4HUQNjr4l0oqsHDIuLma4ExwMew51jD2whzxVXCw9k0&s=10',
  },
  {
    'name': 'Gir National Park',
    'country': 'Gujarat, India',
    'tagline': 'The last wild home of the Asiatic lion',
    'description':
    'A dry deciduous forest reserve where jeep safaris go looking for lions, leopards, '
        'and deer found almost nowhere else on Earth outside East Africa.',
    'imageUrl': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSW1q28DEH2yT_Me7eb0llU-nNnnNHLbTG-rIGslBTqytD_1OeTwIBpniRw&s=10',
  },

  // --- Rest of India ---
  {
    'name': 'Jaipur',
    'country': 'Rajasthan, India',
    'tagline': 'The Pink City',
    'description':
    'Amber Fort, the honeycombed Hawa Mahal, and bazaars selling block-printed textiles '
        'and gemstones — Rajasthan\'s royal capital in rose-pink sandstone.',
    'imageUrl': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRdekhaXVoXe2bT4ZuKhZg965FyfBGWjCaKH98ZTPF-9w&s',
  },
  {
    'name': 'Udaipur',
    'country': 'Rajasthan, India',
    'tagline': 'The City of Lakes',
    'description':
    'Whitewashed palaces float on Lake Pichola, with rooftop cafes, boat rides at sunset, '
        'and the sprawling City Palace overlooking it all.',
    'imageUrl': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT6fAZDJx_Et1F-DqAWD8yi2qCv2zl63RrGRhAPPQzWBybuSvp7vajhPZQt&s=10',
  },
  {
    'name': 'Agra',
    'country': 'Uttar Pradesh, India',
    'tagline': 'Home of the Taj Mahal',
    'description':
    'The marble mausoleum at sunrise is the headline, but Agra Fort and the ghost city '
        'of Fatehpur Sikri nearby are worth the extra day.',
    'imageUrl': 'https://s7ap1.scene7.com/is/image/incredibleindia/1-taj-mahal-agra-uttar-pradesh-city-hero?qlt=82&ts=1726650328155',
  },
  {
    'name': 'Varanasi',
    'country': 'Uttar Pradesh, India',
    'tagline': 'India\'s oldest living city',
    'description':
    'Boat rides on the Ganges at dawn, the nightly Ganga Aarti fire ceremony, and a maze '
        'of ghats and alleyways that feel unchanged for centuries.',
    'imageUrl': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSZLqGlbTJM3kOXg5XNvLhr9Zb1JF5yBxHjJReGtJVWB7iyPOD8eHEtMlI&s=10',
  },
  {
    'name': 'Rishikesh',
    'country': 'Uttarakhand, India',
    'tagline': 'Yoga capital of the world',
    'description':
    'The Ganges rushes clear and cold out of the Himalayan foothills here, past ashrams, '
        'suspension bridges, and white-water rafting stretches.',
    'imageUrl': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS9BfylL7LpkL5sSfcQLg6z-lhcm61bcVCuqNE0_AJUY_drshQmihbVuSHJ&s=10',
  },
  {
    'name': 'Manali',
    'country': 'Himachal Pradesh, India',
    'tagline': 'Gateway to the high Himalayas',
    'description':
    'Pine forests, snow passes like Rohtang and Solang, and a laid-back old-town backpacker '
        'scene make this a favourite base for mountain trips.',
    'imageUrl': 'https://images.pexels.com/photos/31337120/pexels-photo-31337120/free-photo-of-scenic-winter-landscape-of-manali-india.jpeg?cs=tinysrgb&dpr=1&w=500',
  },
  {
    'name': 'Munnar',
    'country': 'Kerala, India',
    'tagline': 'Rolling hills carpeted in tea',
    'description':
    'Emerald tea estates climb every hillside, with misty viewpoints, spice plantations, '
        'and cool weather that\'s rare for this far south.',
    'imageUrl': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTKnN3MvcbmcpKmbF6iv11o0IeAcIHGu2nXuXLvacwXiacltjugvBLV4I4&s=10',
  },
  {
    'name': 'Leh-Ladakh',
    'country': 'Ladakh, India',
    'tagline': 'High-altitude desert and turquoise lakes',
    'description':
    'Monasteries perched on cliffs, the impossibly blue Pangong Lake, and some of the '
        'highest motorable passes on Earth, all above 3,000 metres.',
    'imageUrl': 'https://i0.wp.com/lahimalaya.com/wp-content/uploads/2019/08/Ladakh-trip.jpg?fit=960%2C640&ssl=1',
  },
];