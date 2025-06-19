import 'package:flutter/foundation.dart' show kIsWeb;

/// Constants for route paths used in the app router
class RouteConstants {
  // Base routes
  static const String splash = '/';
  static const String login = '/login';
  static const String createAccount = '/create-account';
  static const String otpVerification = '/otp-verification';
  static const String createProfile = '/create-profile';
  static const String signupSuccess = '/signup-success';
  static const String guestPrompt = '/guest-prompt';
  static const String forgotPassword = '/forgot-password';
  static const String changePassword = '/change-password';
  static const String changePasswordSuccess = '/change-password-success';
  static const String onboarding = '/onboarding';
  
  // Home and main feature routes
  static const String home = '/home';
  static const String homeBrowse = '/home/browse';
  static const String homeTasks = '/home/tasks';
  static const String homeChat = '/home/chat';
  static const String homeProfile = '/home/profile';
  
  // Task related routes
  static const String createTask = '/create-task';
  static const String taskDetails = '/home/tasks/:id';
  static const String applyTask = '/home/tasks/:id/apply';
  
  // Chat related routes
  static const String chatRoom = '/home/chat/:id';
  
  // Payment related routes
  static const String paymentCallback = '/payment/:id';
  
  // Route names (for named navigation)
  static const String splashName = 'splash';
  static const String loginName = 'login';
  static const String createAccountName = 'create-account';
  static const String otpVerificationName = 'otp-verification';
  static const String createProfileName = 'create-profile';
  static const String signupSuccessName = 'signup-success';
  static const String guestPromptName = 'guest-prompt';
  static const String forgotPasswordName = 'forgot-password';
  static const String changePasswordName = 'change-password';
  static const String changePasswordSuccessName = 'change-password-success';
  static const String onboardingName = 'onboarding';
  static const String homeName = 'home';
  static const String tasksName = 'tasks';
  static const String taskDetailsName = 'task-details';
  static const String applyTaskName = 'apply-task';
  static const String createTaskName = 'create-task';
  static const String chatName = 'chat';
  static const String chatRoomName = 'chat-room';
  static const String profileName = 'profile';
  static const String paymentCallbackName = 'payment-callback';
}
