import 'package:flutter/foundation.dart' show kIsWeb;

/// Constants related to API endpoints and configurations
class ApiConstants {
  // Supabase Configuration
  static const String supabaseUrl = 'https://txojopmkgjbqsfcacglz.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR4b2pvcG1rZ2picXNmY2FjZ2x6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk0MzMxODcsImV4cCI6MjA2NTAwOTE4N30.5itLemoP3J_05zZW9qS7yRb4RbBlZ2dy3J6GkDA1rkY';
  
  // Payments / Integrations
  // Toggle to true in development to bypass real Stripe calls
  static const bool mockPayments = false;
  
  // Stripe Configuration
  static const String stripePublishableKey = 'pk_test_51RUxP5PNCUSI0FBOWAUJlNXifjQBUiGQI4VNWcrC7zymgCIWDavy7qetpxYITXe45LCjvVFDNNkafnI8uDbunDyZ00V446s1UF';
  
  // Storage Buckets
  static const String taskImagesBucket = 'task-images';
  
  // API Endpoints
  static const String billplzApiEndpoint = 'https://www.billplz-sandbox.com/api/v3';
  static const String billplzCallbackUrl = 'https://aytxvyemlspkzzmwpqkz.functions.supabase.co/billplz-callback';
  
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
