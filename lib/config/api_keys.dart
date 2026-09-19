/// API keys injected at build/run time via --dart-define, so nothing
/// secret is committed to source control.
///
/// Run with:
///   flutter run --dart-define=GOOGLE_PLACES_API_KEY=your_key_here
/// Build with:
///   flutter build web --dart-define=GOOGLE_PLACES_API_KEY=your_key_here
///
/// Never hardcode a real key in this file.
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiKeys {
  static String get googlePlacesApiKey => dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
}