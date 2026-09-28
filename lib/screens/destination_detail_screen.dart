import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../models/destination.dart';
import 'create_trip_screen.dart';

class DestinationDetailScreen extends StatelessWidget {
  final Destination destination;

  const DestinationDetailScreen({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _HeroImage(destination: destination),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.inkMuted),
                    const SizedBox(width: 4),
                    Text(
                      destination.country,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.inkMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  destination.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
                if (destination.galleryImages.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Text('Photos', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ...destination.galleryImages.map((url) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(
                          aspectRatio: 16 / 10,
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppTheme.canvas,
                              child: const Icon(Icons.broken_image_outlined,
                                  size: 40, color: AppTheme.inkMuted),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateTripScreen(
                          prefilledDestination: destination.name,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Plan a Trip'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A full-width hero image behind the transparent app bar, with the
/// destination's name and tagline overlaid at the bottom via a gradient
/// scrim — the thing a person notices first on a place they're
/// considering, rather than a bare title bar.
class _HeroImage extends StatelessWidget {
  final Destination destination;

  const _HeroImage({required this.destination});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            destination.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: AppTheme.indigoNight),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                stops: const [0.4, 1],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  destination.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  destination.tagline,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}