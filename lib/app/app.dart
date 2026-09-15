import 'package:flutter/material.dart';
import 'theme.dart';
import 'routes.dart';
import '../screens/splash_screen.dart';
import '../screens/home_screen.dart';
import '../screens/create_trip_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/login_screen.dart';

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
        AppRoutes.signup: (context) => const SignupScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.home: (context) => const HomeScreen(),
        AppRoutes.createTrip: (context) => const CreateTripScreen(),
      },
    );
  }
}