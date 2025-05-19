import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Taskaway Malaysia';
  
  // Supabase Configuration
  static const String supabaseUrl = 'https://aytxvyemlspkzzmwpqkz.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF5dHh2eWVtbHNwa3p6bXdwcWt6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE0MTIzMzMsImV4cCI6MjA1Njk4ODMzM30.MnwbHavRic_3IiW2cK1uISlMlQa7j8vsK2OL1fFGijI';
  
  // API Endpoints
  static const String billplzApiEndpoint = 'https://www.billplz-sandbox.com/api/v3';
  
  // Table Names
  static const String tasksTable = 'taskaway_tasks';
  static const String applicationsTable = 'taskaway_applications';
  static const String messagesTable = 'taskaway_messages';
  static const String paymentsTable = 'taskaway_payments';
  static const String profilesTable = 'taskaway_profiles';
  
  // Asset Paths
  static const String imagePath = 'assets/images';
  static const String iconPath = 'assets/icons';
  
  // Colors
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color secondaryColor = Color(0xFF64748B);
  static const Color errorColor = Color(0xFFDC2626);
  static const Color successColor = Color(0xFF16A34A);
  
  // Spacing
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 8.0;
  
  // Animation Durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
} 