import 'package:flutter/material.dart';
import '../models/destination.dart';
import 'create_trip_screen.dart';

class DestinationDetailScreen extends StatelessWidget {
  final Destination destination;

  const DestinationDetailScreen({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(destination.name),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.black54),
                const SizedBox(width: 4),
                Text(
                  destination.country,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              destination.tagline,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              destination.description,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
            if (destination.galleryImages.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text(
                'Photos',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
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
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.broken_image_outlined, size: 40),
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
    );
  }
}