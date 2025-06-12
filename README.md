# Taskaway Malaysia

A task outsourcing platform for Malaysia built with Flutter, Riverpod, and Supabase.

## Project Structure

The project follows a modular architecture organized by features:

```
taskaway/
├── assets/
│   ├── fonts/     # Font files
│   ├── images/    # Image assets
│   └── icons/     # Icon assets
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   ├── api_constants.dart    # API and Supabase configuration
│   │   │   ├── asset_constants.dart  # Asset paths
│   │   │   ├── constants.dart        # Barrel file for all constants
│   │   │   ├── db_constants.dart     # Database table names
│   │   │   └── style_constants.dart  # UI styling constants
│   │   ├── services/
│   │   │   ├── billplz_service.dart  # Payment gateway service
│   │   │   └── supabase_service.dart # Supabase client service
│   │   ├── theme/
│   │   │   └── app_theme.dart       # App theme configuration
│   │   └── utils/
│   │       └── string_extensions.dart # String utility extensions
│   ├── features/
│   │   ├── auth/         # Authentication feature
│   │   │   ├── controllers/   # Auth business logic
│   │   │   ├── models/        # Auth data models
│   │   │   ├── repositories/  # Auth data access
│   │   │   └── screens/       # Auth UI screens
│   │   ├── home/         # Home screen feature
│   │   │   └── screens/       # Home UI screens
│   │   ├── messages/     # Messaging feature
│   │   │   ├── controllers/   # Message business logic
│   │   │   ├── models/        # Message data models
│   │   │   ├── repositories/  # Message data access
│   │   │   └── screens/       # Message UI screens
│   │   ├── payments/     # Payment processing feature
│   │   │   ├── controllers/   # Payment business logic
│   │   │   ├── models/        # Payment data models
│   │   │   └── screens/       # Payment UI screens
│   │   ├── splash/       # Splash screen feature
│   │   │   └── screens/       # Splash UI screen
│   │   └── tasks/        # Task management feature
│   │       ├── controllers/   # Task business logic
│   │       ├── models/        # Task data models
│   │       ├── repositories/  # Task data access
│   │       └── screens/       # Task UI screens
│   ├── shared/           # Shared components
│   │   └── widgets/      # Reusable widgets
│   ├── routes/           # App routing
│   │   └── app_router.dart # GoRouter configuration
│   └── main.dart         # Application entry point
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
