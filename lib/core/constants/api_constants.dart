import 'package:flutter/foundation.dart' show kIsWeb;

/// Constants related to API endpoints and configurations
class ApiConstants {
  // Supabase Configuration
  static const String supabaseUrl = 'https://aytxvyemlspkzzmwpqkz.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF5dHh2eWVtbHNwa3p6bXdwcWt6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE0MTIzMzMsImV4cCI6MjA1Njk4ODMzM30.MnwbHavRic_3IiW2cK1uISlMlQa7j8vsK2OL1fFGijI';
  
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
