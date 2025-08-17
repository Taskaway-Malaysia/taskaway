import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

/// Helper class for debugging that outputs to both developer console and browser console
class DebugLogger {
  static void log(String message) {
    // Always use developer log
    print(message);
    
    // For web, also print to browser console
    if (kIsWeb) {
      // ignore: avoid_print
      print('[DEBUG] $message');
    }
    
    // In debug mode, also use debugPrint
    if (kDebugMode) {
      print(message);
    }
  }
  
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    print('ERROR: $message${error != null ? ' - Error: $error' : ''}${stackTrace != null ? '\nStackTrace: $stackTrace' : ''}');
    
    if (kIsWeb) {
      // ignore: avoid_print
      print('[ERROR] $message');
      if (error != null) {
        // ignore: avoid_print
        print('[ERROR DETAIL] $error');
      }
    }
    
    if (kDebugMode) {
      print('ERROR: $message');
      if (error != null) {
        print('Error details: $error');
      }
    }
  }
}