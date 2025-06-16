# Taskaway Malaysia

A task outsourcing platform for Malaysia built with Flutter, Riverpod, and Supabase.

## Project Structure

The project follows a clean architecture with feature-first organization:

```
taskaway/
├── assets/
│   ├── fonts/          # Custom font files
│   ├── images/         # Image assets
│   └── icons/          # App icons and vector assets
├── lib/
│   ├── core/
│   │   ├── constants/    # Application-wide constants
│   │   │   ├── api_constants.dart    # API and service configurations
│   │   │   ├── asset_constants.dart  # Asset path constants
│   │   │   ├── constants.dart        # Barrel file for all constants
│   │   │   ├── db_constants.dart     # Database table and field names
│   │   │   └── style_constants.dart  # UI styling and theming constants
│   │   │
│   │   ├── theme/        # App theming and styling
│   │   │   └── app_theme.dart        # Theme configuration and extensions
│   │   │
│   │   ├── utils/        # Utility functions and extensions
│   │   │   ├── states.dart          # Common state definitions
│   │   │   └── string_extensions.dart # String utility extensions
│   │   │
│   │   └── widgets/      # Reusable widget components
│   │       ├── numpad_overlay.dart  # Custom numpad input widget
│   │       └── qwerty_overlay.dart  # Custom keyboard widget
│   │
│   ├── features/      # Feature modules (each feature is self-contained)
│   │   │
│   │   ├── auth/         # Authentication feature
│   │   │   ├── controllers/
│   │   │   │   └── auth_controller.dart  # Authentication logic
│   │   │   │
│   │   │   ├── models/
│   │   │   │   ├── profile.dart         # User profile model
│   │   │   │   ├── profile.freezed.dart  # Freezed model
│   │   │   │   └── profile.g.dart       # JSON serialization
│   │   │   │
│   │   │   ├── screens/
│   │   │   │   ├── auth_screen.dart              # Main auth screen
│   │   │   │   ├── change_password_screen.dart    # Password change
│   │   │   │   ├── change_password_success_screen.dart
│   │   │   │   ├── create_account_screen.dart     # User registration
│   │   │   │   ├── create_profile_screen.dart     # Profile creation
│   │   │   │   ├── forgot_password_screen.dart    # Password recovery
│   │   │   │   ├── otp_verification_screen.dart   # OTP verification
│   │   │   │   └── signup_success_screen.dart     # Signup completion
│   │   │   │
│   │   │   └── widgets/
│   │   │       └── guest_prompt_overlay.dart  # Guest mode prompt
│   │   │
│   │   ├── home/          # Home/Dashboard feature
│   │   │   └── screens/
│   │   │       └── home_screen.dart  # Main dashboard
│   │   │
│   │   ├── messages/      # Messaging feature
│   │   │   ├── controllers/
│   │   │   │   └── message_controller.dart  # Message handling
│   │   │   │
│   │   │   ├── models/
│   │   │   │   ├── channel.dart  # Chat channel model
│   │   │   │   └── message.dart  # Message model
│   │   │   │
│   │   │   ├── repositories/
│   │   │   │   └── message_repository.dart  # Message data access
│   │   │   │
│   │   │   └── screens/
│   │   │       ├── chat_list_screen.dart  # Conversations list
│   │   │       └── chat_screen.dart       # Individual chat
│   │   │
│   │   ├── payments/      # Payment processing
│   │   │   ├── controllers/
│   │   │   │   └── payment_controller.dart  # Payment processing
│   │   │   │
│   │   │   ├── models/
│   │   │   │   └── payment.dart  # Payment model
│   │   │   │
│   │   │   ├── screens/
│   │   │   │   └── payment_completion_screen.dart  # Payment result
│   │   │   │
│   │   │   └── services/
│   │   │       └── billplz_service.dart  # Billplz integration
│   │   │
│   │   ├── profile/       # User profile management
│   │   │   └── screens/
│   │   │       └── profile_screen.dart  # User profile
│   │   │
│   │   ├── splash/        # Splash screen and initial loading
│   │   │   └── screens/
│   │   │       └── splash_screen.dart  # Initial loading screen
│   │   │
│   │   └── tasks/         # Task management
│   │       ├── models/
│   │       │   ├── task.dart          # Task model
│   │       │   ├── task.freezed.dart  # Freezed model
│   │       │   ├── task.g.dart       # JSON serialization
│   │       │   └── task_status.dart  # Task status enum
│   │       │
│   │       └── screens/
│   │           ├── apply_task_screen.dart    # Task application
│   │           ├── create_task_screen.dart   # Task creation
│   │           ├── my_tasks_screen.dart      # User's tasks
│   │           ├── task_details_screen.dart  # Task details
│   │           └── tasks_screen.dart         # Task listings
│   │
│   ├── routes/         # App routing configuration
│   │   └── app_router.dart  # GoRouter configuration
│   │
│   └── main.dart       # Application entry point
```
```

## Features

- **Authentication**: User registration and login with Supabase Auth
- **Task Management**: Create, browse, and apply for tasks
- **Messaging**: Real-time chat between task posters and applicants with unread message indicators
- **Payments**: Integrated payment processing with Billplz gateway
- **Responsive UI**: Material 3 design with proper theming

## Technology Stack

- **Frontend**: Flutter with Riverpod for state management
- **Backend**: Supabase for authentication, database, storage, and real-time features
- **State Management**: Riverpod with AsyncValue for proper loading/error states
- **Routing**: GoRouter for navigation and deep linking
- **Payment**: Billplz payment gateway integration
- **Code Generation**: Freezed for immutable models

## Getting Started

### Prerequisites

- Flutter SDK (>=3.19.0)
- Dart SDK (>=3.2.0)
- Supabase account

### Installation

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Configure your Supabase credentials in `lib/core/constants/api_constants.dart`
4. Run the app with `flutter run`

### Development

- Use `flutter pub run build_runner build --delete-conflicting-outputs` to generate code for Freezed models and Riverpod providers
- Run `flutter analyze` to check for lint issues
- Follow the modular architecture when adding new features
