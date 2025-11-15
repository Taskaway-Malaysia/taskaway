import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Constants related to API endpoints and configurations
/// All sensitive values are loaded from environment variables
class ApiConstants {
  // Supabase Configuration
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Payments / Integrations
  // All payments now handled via CHIPP Gateway through Supabase Edge Functions
  static bool get mockPayments => dotenv.env['MOCK_PAYMENTS']?.toLowerCase() == 'true';

  // Storage Buckets
  static const String taskImagesBucket = 'task-images';

  // MapTiler Configuration
  static String get mapTilerApiKey => dotenv.env['MAPTILER_API_KEY'] ?? '';
  static const String mapTilerStyleUrl = 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=';

  // Google Maps Configuration
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  // API Endpoints
  static String get billplzApiEndpoint => dotenv.env['BILLPLZ_API_ENDPOINT'] ?? 'https://www.billplz-sandbox.com/api/v3';
  static String get billplzCallbackUrl => dotenv.env['BILLPLZ_CALLBACK_URL'] ?? '';
  
  // For web, use the current origin. For mobile, use deep linking.
  static String getRedirectUrl(String paymentId) {
    if (kIsWeb) {
      final origin = Uri.base.origin;
      return '$origin/payment/$paymentId';
    } else {
      return 'taskaway://payment/$paymentId';
    }
  }
}
