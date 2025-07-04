# Analytics Setup Guide for TaskAway

## Overview

TaskAway uses Firebase Analytics to track user behavior, app performance, and business metrics. This guide covers the analytics implementation and how to use it.

## Current Setup Status ✅

- **Firebase Analytics** package added to `pubspec.yaml`
- **Analytics Service** created at `lib/core/services/analytics_service.dart`
- **Route Observer** integrated for automatic screen tracking
- **Authentication Events** tracked (signup, login, logout)

## Analytics Service Features

### User Properties
- User ID
- User Role (poster/tasker)
- User Name
- User Email

### Tracked Events

#### Authentication
- `sign_up` - When user creates account
- `login` - When user logs in
- `logout` - When user logs out

#### Task Management
- `task_created` - When poster creates a task
- `task_viewed` - When user views task details
- `task_applied` - When tasker applies for task
- `task_completed` - When task is marked complete

#### Payments
- `payment_initiated` - When payment process starts
- `purchase` - When payment completes (standard Firebase event)
- `payment_failed` - When payment fails

#### Messaging
- `message_sent` - When user sends a message

#### Search
- `search` - When user performs search (standard Firebase event)

#### Ratings
- `rating_given` - When user rates another user

#### Screen Views
- Automatically tracked via `FirebaseAnalyticsObserver`

## Implementation Examples

### 1. Track Task Creation

```dart
// In create_task_screen.dart
import 'package:taskaway/core/services/analytics_service.dart';

// Inside your widget
final analytics = ref.read(analyticsServiceProvider);

// When task is created
await analytics.logTaskCreated(
  taskId: newTask.id,
  category: newTask.category,
  price: newTask.price,
);
```

### 2. Track Task View

```dart
// In task_details_screen.dart
@override
void initState() {
  super.initState();
  
  // Track task view
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final analytics = ref.read(analyticsServiceProvider);
    analytics.logTaskViewed(
      taskId: widget.taskId,
      category: task.category,
    );
  });
}
```

### 3. Track Custom Events

```dart
// For any custom event
await analytics.logCustomEvent(
  eventName: 'profile_photo_uploaded',
  parameters: {
    'file_size': fileSize,
    'upload_duration': uploadTime,
  },
);
```

### 4. Set User Properties

```dart
// After user profile is loaded
await analytics.setUserProperties(
  userRole: profile.role,
  userName: profile.name,
  userEmail: profile.email,
);
```

## Viewing Analytics Data

### Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select `flutter-staging-taskaway` project
3. Navigate to Analytics in the left menu

### Key Reports

1. **Dashboard** - Overview of user activity
2. **Events** - All tracked events and their counts
3. **Conversions** - Key business metrics
4. **Audiences** - User segments
5. **Funnels** - User flow analysis
6. **User Properties** - Custom user attributes

### DebugView (For Testing)

Enable debug mode to see events in real-time:

```bash
# For Android
adb shell setprop debug.firebase.analytics.app my.taskaway.taskaway

# For iOS (in Xcode scheme)
-FIRDebugEnabled
```

## Adding New Events

To add a new analytics event:

1. Add method to `analytics_service.dart`:
```dart
Future<void> logNewFeatureUsed({
  required String featureName,
  Map<String, dynamic>? additionalParams,
}) async {
  try {
    await _analytics.logEvent(
      name: 'feature_used',
      parameters: {
        'feature_name': featureName,
        ...?additionalParams,
      },
    );
    _logger.i('Analytics: Feature used - $featureName');
  } catch (e) {
    _logger.e('Analytics: Error logging feature use', error: e);
  }
}
```

2. Call it where needed:
```dart
await analytics.logNewFeatureUsed(
  featureName: 'voice_message',
  additionalParams: {'duration': messageDuration},
);
```

## Best Practices

### 1. Event Naming
- Use snake_case for event names
- Be descriptive but concise
- Follow Firebase's naming conventions

### 2. Parameter Values
- Keep parameter values under 100 characters
- Use consistent parameter names across events
- Limit to 25 parameters per event

### 3. User Privacy
- Don't log personally identifiable information (PII)
- Follow GDPR/privacy regulations
- Allow users to opt-out if required

### 4. Performance
- Analytics calls are asynchronous and batched
- Don't worry about calling too frequently
- Events are queued offline and sent when connected

## Testing Analytics

### 1. Use DebugView
```bash
# Enable debug mode
adb shell setprop debug.firebase.analytics.app my.taskaway.taskaway

# View in Firebase Console > Analytics > DebugView
```

### 2. Check Logs
```dart
// Analytics service logs all events
// Check console output for "Analytics:" prefix
```

### 3. Verify in Firebase Console
- Events appear in Firebase Console within 24 hours
- DebugView shows events in real-time

## Monitoring & Alerts

### Set up Conversion Events
1. Go to Firebase Console > Analytics > Events
2. Mark important events as conversions:
   - `task_completed`
   - `purchase`
   - `sign_up`

### Create Audiences
1. Go to Analytics > Audiences
2. Create segments like:
   - Active Posters (created task in last 7 days)
   - Active Taskers (applied to task in last 7 days)
   - Paying Users (completed payment)

### Set up Alerts
1. Use Firebase Cloud Messaging
2. Trigger based on analytics events
3. Re-engage users based on behavior

## Integration with Other Services

### Google Analytics 4 (GA4)
Firebase Analytics is built on GA4. To link:
1. Go to Firebase Console > Project Settings
2. Navigate to Integrations
3. Link to Google Analytics

### BigQuery Export
For advanced analysis:
1. Enable BigQuery export in Firebase Console
2. Query raw event data
3. Build custom dashboards

## Troubleshooting

### Events Not Appearing
1. Check if analytics is enabled in Firebase Console
2. Verify Firebase configuration files are correct
3. Use DebugView to test
4. Wait 24 hours for regular reporting

### User Properties Not Updating
1. Ensure you're setting properties after user authentication
2. Properties are strings with 36 character limit
3. Check Firebase Console > User Properties

### Performance Impact
- Analytics has minimal impact
- Events are batched and sent periodically
- Offline events are queued

## Next Steps

1. **Add More Events**: Implement tracking for remaining features
2. **Set up Dashboards**: Create custom reports in Firebase Console
3. **Define KPIs**: Establish key metrics to track
4. **A/B Testing**: Use Firebase Remote Config with Analytics
5. **Crash Reporting**: Add Firebase Crashlytics for complete monitoring

## Quick Reference

```dart
// Get analytics instance
final analytics = ref.read(analyticsServiceProvider);

// Common events
await analytics.logScreenView(screenName: 'home');
await analytics.logSearch(searchTerm: 'plumber');
await analytics.logTaskCreated(taskId: '123', category: 'cleaning', price: 50.0);
await analytics.logPaymentCompleted(paymentId: '456', amount: 50.0, currency: 'MYR', paymentMethod: 'billplz');
```