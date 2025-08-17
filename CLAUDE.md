# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Essential Commands

```bash
# Development
flutter run                    # Run on default device
flutter run -d chrome          # Run on Chrome
flutter run -d ios             # Run on iOS Simulator
flutter run -d android         # Run on Android emulator

# Code Generation (REQUIRED after modifying models/providers)
flutter pub run build_runner build --delete-conflicting-outputs
./tool/build.sh               # Alternative helper script

# Dependencies & Analysis
flutter pub get               # Install dependencies
flutter analyze               # Check for code issues
flutter test                  # Run tests (limited coverage)
flutter clean                 # Clean build artifacts

# Hot Reload/Restart (while app is running)
r                            # Hot reload
R                            # Hot restart
q                            # Quit
```

## Architecture & Business Logic

### Core Workflow (from activity_diagram.puml)

The platform operates on this task lifecycle:

1. **Guest Mode** → Browse only, must register to interact
2. **Task Creation** → Status: `open`
3. **Offer Submission** → Status: `pending` 
4. **Payment Authorization** → Stripe checkout before acceptance
5. **Offer Acceptance** → Status: `accepted`, chat enabled
6. **Work Execution** → Status: `in_progress`
7. **Completion Review** → Status: `pending_approval` (with rework cycle)
8. **Final Approval** → Payment captured, status: `completed`
9. **Post-Completion** → Platform fee deduction, manual payout, reviews

**Critical Business Rule**: Posters cannot accept their own offers (self-accept prevention in `application_controller.dart`)

### Database Schema

All tables use `taskaway_` prefix:
- `taskaway_profiles` - User accounts and profiles
- `taskaway_tasks` - Task listings with status tracking
- `taskaway_applications` - Offers from taskers
- `taskaway_messages` - Chat messages (enabled post-acceptance)
- `taskaway_payments` - Transaction records
- `taskaway_payment_methods` - Saved payment methods

### State Management Architecture

**Riverpod Pattern**:
```dart
// Controllers extend AsyncNotifier
class SomeController extends AsyncNotifier<ReturnType> {
  // Loading state
  state = const AsyncValue.loading();
  
  // Success state  
  state = AsyncValue.data(result);
  
  // Error state
  state = AsyncValue.error(error, stackTrace);
}

// Providers use @riverpod annotation for code generation
@riverpod
Future<Something> fetchSomething(Ref ref) async { }
```

### Navigation & Access Control

**GoRouter Configuration** (`app_router.dart`):
- Unauthenticated → Redirects to auth screens
- Guest mode → Limited browsing access
- Authenticated → Full feature access
- Profile incomplete → Redirects to profile creation
- Payment callbacks → Deep linking support

### Payment Flow Implementation

**Stripe Integration** (`payment_controller.dart`, `stripe_service.dart`):
1. Create PaymentIntent when accepting offer
2. Authorize payment before task acceptance
3. Hold funds until task completion
4. Capture payment after approval
5. Deduct platform fee
6. Manual payout to tasker

**Mock Mode**: Set `mockPayments = true` in `api_constants.dart` for development

## Project Structure

```
lib/
├── core/
│   ├── constants/        # API configs, style constants
│   ├── services/         # Supabase initialization
│   ├── theme/            # Material 3 theming
│   └── widgets/          # Shared UI components
├── features/             # Feature modules
│   ├── [feature]/
│   │   ├── controllers/  # Business logic (Riverpod)
│   │   ├── models/       # Data models (Freezed)
│   │   ├── repositories/ # Data access layer
│   │   ├── screens/      # UI screens
│   │   └── widgets/      # Feature-specific widgets
├── routes/               # GoRouter configuration
└── main.dart            # Entry point
```

## Critical Implementation Files

- `lib/features/applications/controllers/application_controller.dart` - Offer acceptance logic with self-accept prevention
- `lib/features/payments/controllers/payment_controller.dart` - Payment flow orchestration
- `lib/features/tasks/repositories/task_repository.dart` - Task CRUD operations
- `lib/routes/app_router.dart` - Route guards and navigation logic
- `lib/core/constants/api_constants.dart` - Supabase config (currently hardcoded)

## Development Patterns

### Adding New Features
1. Create feature folder under `lib/features/`
2. Implement controller extending `AsyncNotifier`
3. Create Freezed models with `@freezed` annotation
4. Run code generation: `flutter pub run build_runner build --delete-conflicting-outputs`
5. Add repository for data operations
6. Build screens using controllers via `ref.watch()`

### Modifying Data Models
1. Update model with `@freezed` and `@JsonSerializable()`
2. Run code generation (models won't work without this)
3. Update repository methods
4. Update controller logic

### Working with Supabase
- Client initialized in `supabase_service.dart`
- All queries use `SupabaseService.client`
- Real-time subscriptions for messaging
- Row Level Security should be configured in Supabase dashboard

## Current Configuration

- **Supabase URL**: `https://txojopmkgjbqsfcacglz.supabase.co`
- **Payment Gateway**: Stripe (primary), Billplz (alternative)
- **Mock Payments**: Enabled in development
- **Target Market**: Malaysia
- **Min Flutter SDK**: 3.2.0

## Known Issues & Considerations

- API keys hardcoded in `api_constants.dart` (should use environment variables)
- Limited test coverage
- Large screen files (e.g., `create_task_screen.dart` at 42KB) need refactoring
- Firebase Analytics integrated but may need configuration
- Manual payout system requires admin intervention