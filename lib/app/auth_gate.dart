import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/auth_providers.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';

/// Shown right after the splash screen. Watches the live Firebase auth
/// stream and decides whether to show Home (signed in) or Login
/// (signed out) — this is what lets a returning signed-in user skip
/// the login flow on app restart.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (user) => user != null ? const HomeScreen() : const LoginScreen(),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Something went wrong: $error')),
      ),
    );
  }
}