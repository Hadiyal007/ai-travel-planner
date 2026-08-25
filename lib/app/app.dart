import 'package:flutter/material.dart';
import 'theme.dart';
import 'routes.dart';
import '../screens/splash_screen.dart';

class TravelPlannerApp extends StatelessWidget {
  const TravelPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Travel Planner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        // more routes get added here as we build each screen
      },
    );
  }
}