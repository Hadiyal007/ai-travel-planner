import 'package:flutter/material.dart';
import '../app/theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.travel_explore, size: 72, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'AI Travel Planner',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}