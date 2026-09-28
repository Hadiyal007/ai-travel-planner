import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../app/routes.dart';
import '../widgets/brand_mark.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.authGate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.indigoNight,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // A passport-stamp ring around the mark, rather than a bare
            // icon — the one bold gesture on this screen.
            const BrandMark(size: 96, iconColor: Colors.white),
            const SizedBox(height: 24),
            Text(
              'AI Travel Planner',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Plans that actually fit your trip',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}