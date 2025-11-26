import 'dart:async'; // Required for StreamSubscription
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart'; // Required for ChangeNotifier
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'package:taskaway/features/auth/models/profile.dart'; // For Profile model
import 'dart:developer' as dev;
import 'package:taskaway/core/services/analytics_service.dart';

final authControllerProvider = StateNotifierProvider<AuthController, bool>((ref) {
  return AuthController(
    supabase: Supabase.instance.client,
    analytics: ref.read(analyticsServiceProvider),
  );
});

/// Provider to track if the user is in the password recovery flow.
/// This helps manage navigation state across widget rebuilds, especially during initial app load.
final passwordRecoveryFlowProvider = StateProvider<bool>((ref) => false);

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

/// Provider to fetch the current user's profile including role information
final currentProfileProvider = StreamProvider.autoDispose<Profile?>((ref) {
  final authState = ref.watch(authStateProvider);

  final user = authState.value?.session?.user;

  if (user == null) {
    return Stream.value(null);
  }

  try {
    return Supabase.instance.client
        .from('taskaway_profiles')
        .stream(primaryKey: ['id'])
        .eq('id', user.id)
        .limit(1)
        .map((data) => data.isEmpty ? null : Profile.fromJson(data.first));
  } catch (e) {
    print('Error creating profile stream: $e');
    return Stream.value(null);
  }
});

/// Provider to fetch any user's profile by their ID
final profileProvider = StreamProvider.family.autoDispose<Profile?, String>((ref, userId) {
  if (userId.isEmpty) {
    return Stream.value(null);
  }
  try {
    return Supabase.instance.client
        .from('taskaway_profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .limit(1)
        .map((data) => data.isEmpty ? null : Profile.fromJson(data.first));
  } catch (e) {
    print('Error creating profile stream for userId: $userId - Error: $e');
    return Stream.value(null);
  }
});

/// Provider to fetch user's auth metadata including last sign-in time
final userAuthMetadataProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
  if (userId.isEmpty) {
    return null;
  }

  try {
    // Query the auth.users table through a Supabase function or RPC call
    // Note: Direct access to auth.users requires admin privileges
    // We'll try to get the user's metadata from the authenticated user if it's the current user
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null && currentUser.id == userId) {
      // For current user, we can access their metadata directly
      return {
        'last_sign_in_at': currentUser.lastSignInAt,
        'created_at': currentUser.createdAt,
        'email': currentUser.email,
      };
    }

    // For other users, we'll need to fetch from profiles or use an RPC function
    // For now, we'll return null and can enhance this with an Edge Function later
    return null;
  } catch (e) {
    print('Error fetching user auth metadata for userId: $userId - Error: $e');
    return null;
  }
});

class AuthController extends StateNotifier<bool> {
  final SupabaseClient supabase;
  final AnalyticsService analytics;

  AuthController({required this.supabase, required this.analytics}) : super(false);
  
  // Get the current user
  User? get currentUser => supabase.auth.currentUser;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    state = true;
    try {
      // TASK-NEW: Removed broken Edge Function call to 'check-user-exists'
      // Supabase Auth already handles duplicate user detection automatically
      // The Edge Function was trying to query non-existent 'public.user_emails' table

      // Proceed with sign-up - Supabase will return error if user already exists
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: data,
      );

      final user = response.user;

      if (user == null) {
        throw const AuthException('An unexpected error occurred. Please try again.');
      }

      // Log analytics for the new user
      await analytics.logSignUp(signUpMethod: 'email');
      await analytics.setUserId(user.id);
      return response;

    } finally {
      state = false;
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    state = true;
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Log analytics event and update last sign-in time
      if (response.user != null) {
        await analytics.logLogin(loginMethod: 'email');
        await analytics.setUserId(response.user!.id);

        // Update profile with last sign-in time
        try {
          await supabase.from('taskaway_profiles').update({
            'last_sign_in_at': DateTime.now().toIso8601String(),
          }).eq('id', response.user!.id);
        } catch (e) {
          print('Failed to update last_sign_in_at: $e');
        }
      }

      return response;
    } finally {
      state = false;
    }
  }

  /// Sign in with Apple
  ///
  /// This method handles Apple Sign-in flow:
  /// 1. Generates a secure nonce for the authentication request
  /// 2. Requests Apple credentials (including optional email/fullName on first sign-in)
  /// 3. Authenticates with Supabase using the Apple ID token and raw nonce
  /// 4. Updates analytics and profile metadata
  ///
  /// Note: Apple only provides email and name on the FIRST sign-in attempt.
  /// Subsequent sign-ins will have null email/fullName in the credential.
  Future<AuthResponse> signInWithApple() async {
    state = true;
    try {
      // Check if Apple Sign-in is available on this platform
      if (!Platform.isIOS && !Platform.isMacOS) {
        throw const AuthException('Apple Sign-in is only available on iOS and macOS');
      }

      // Generate raw nonce and hash it for Apple Sign-in
      final rawNonce = supabase.auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      // Request Apple credentials with hashed nonce
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const AuthException('Could not find ID Token from generated credential.');
      }

      // Sign in with Supabase using the ID token and raw nonce
      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      // Log analytics event
      if (response.user != null) {
        await analytics.logLogin(loginMethod: 'apple');
        await analytics.setUserId(response.user!.id);

        // Apple only provides the user's full name on the first sign-in
        // Save it to user metadata if available
        if (credential.givenName != null || credential.familyName != null) {
          final nameParts = <String>[];
          if (credential.givenName != null) nameParts.add(credential.givenName!);
          if (credential.familyName != null) nameParts.add(credential.familyName!);
          final fullName = nameParts.join(' ');

          await supabase.auth.updateUser(
            UserAttributes(
              data: {
                'full_name': fullName,
                'given_name': credential.givenName,
                'family_name': credential.familyName,
              },
            ),
          );
        }

        // Update profile with last sign-in time
        try {
          await supabase.from('taskaway_profiles').update({
            'last_sign_in_at': DateTime.now().toIso8601String(),
          }).eq('id', response.user!.id);
        } catch (e) {
          print('Failed to update last_sign_in_at: $e');
        }
      }

      return response;
    } on SignInWithAppleAuthorizationException catch (e) {
      // Handle Apple Sign-in specific errors
      switch (e.code) {
        case AuthorizationErrorCode.canceled:
          throw const AuthException('Apple Sign-in was canceled');
        case AuthorizationErrorCode.failed:
          throw const AuthException('Apple Sign-in failed');
        case AuthorizationErrorCode.invalidResponse:
          throw const AuthException('Invalid response from Apple');
        case AuthorizationErrorCode.notHandled:
          throw const AuthException('Apple Sign-in not handled');
        case AuthorizationErrorCode.unknown:
        default:
          throw AuthException('Apple Sign-in error: ${e.message}');
      }
    } catch (e) {
      print('Error during Apple Sign-in: $e');
      rethrow;
    } finally {
      state = false;
    }
  }

  Future<void> signOut() async {
    state = true;
    try {
      await analytics.logLogout();
      await supabase.auth.signOut();
    } finally {
      state = false;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = true;
    try {
      await supabase.auth.resetPasswordForEmail(email);
    } finally {
      state = false;
    }
  }
  
  // Verify OTP for signup or password recovery
  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
    required OtpType type,
  }) async {
    state = true;
    try {
      print('Verifying OTP: $email, token: $token, type: $type');
      final response = await supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: type,
      );
      return response;
    } catch (e) {
      print('Error verifying OTP: $e');
      rethrow;
    } finally {
      state = false;
    }
  }
  
  // Resend OTP for signup or password recovery
  Future<void> resendOtp({
    required String email,
    required OtpType type,
  }) async {
    state = true;
    try {
      print('Resending OTP to: $email, type: $type');
      if (type == OtpType.recovery) {
        await sendPasswordResetEmail(email);
      } else {
        await supabase.auth.resend(
          email: email,
          type: type,
        );
      }
    } catch (e) {
      print('Error resending OTP: $e');
      rethrow;
    } finally {
      state = false;
    }
  }

  Future<UserResponse> updatePassword(String newPassword) async {
    state = true;
    try {
      final response = await supabase.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );
      return response;
    } finally {
      state = false;
    }
  }

  Future<UserResponse> updateUserMetadata(Map<String, dynamic> metadata) async {
    state = true;
    try {
      print('Updating user metadata: $metadata');
      final response = await supabase.auth.updateUser(
        UserAttributes(
          data: metadata,
        ),
      );
      print('User metadata updated successfully: ${response.user?.userMetadata}');
      return response;
    } catch (e) {
      print('Error updating user metadata: $e');
      rethrow;
    } finally {
      state = false;
    }
  }
}

// Notifier for GoRouter to listen to auth changes
class AuthNotifier extends ChangeNotifier {
  AuthNotifier(Ref ref) {
    // Keep the profile provider alive as long as the user is authenticated
    final sub = ref.listen(currentProfileProvider, (_, __) {});
    ref.onDispose(() => sub.close());

    ref.listen(authStateProvider, (_, __) {
      notifyListeners();
    });
  }
}

final isGuestModeProvider = StateProvider<bool>((ref) => false);

final authNotifierProvider = ChangeNotifierProvider<AuthNotifier>((ref) {
  // Ensure this provider is correctly set up to depend on authStateProvider if needed,
  // or directly listen as shown above.
  return AuthNotifier(ref);
});