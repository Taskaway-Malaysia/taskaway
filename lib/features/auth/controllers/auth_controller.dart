import 'dart:async'; // Required for StreamSubscription
import 'package:flutter/material.dart'; // Required for ChangeNotifier
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
/// This helps manage navigation state across widget rebuilds, especially in SplashScreen.
final passwordRecoveryFlowProvider = StateProvider<bool>((ref) => false);

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

/// Provider to fetch the current user's profile including role information
final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  // React to changes in auth state
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (state) async {
      final user = state.session?.user;
      if (user == null) {
        return null;
      }
      try {
        final data = await Supabase.instance.client
            .from('taskaway_profiles')
            .select()
            .eq('id', user.id)
            .single();
        return Profile.fromJson(data);
      } catch (e) {
        dev.log('Error fetching profile', error: e);
        return null;
      }
    },
    loading: () => null, // Or a specific loading state representation
    error: (error, stackTrace) {
      dev.log('Error in auth state', error: error, stackTrace: stackTrace);
      return null;
    },
  );
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
      // 1. Check if the user already exists using the Edge Function.
      final userExistsResponse = await supabase.functions.invoke(
        'check-user-exists',
        body: {'email': email},
      );

      if (userExistsResponse.data['exists']) {
        throw const AuthException('A user with this email already exists. Please sign in.');
      }

      // 2. If the user does not exist, proceed with sign-up.
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: data,
      );

      final user = response.user;

      // This check is for safety, though the edge function should prevent this.
      if (user == null) {
        throw const AuthException('An unexpected error occurred. Please try again.');
      }

      // 3. Log analytics for the new user.
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
      
      // Log analytics event
      if (response.user != null) {
        await analytics.logLogin(loginMethod: 'email');
        await analytics.setUserId(response.user!.id);
      }
      
      return response;
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
      dev.log('Verifying OTP: $email, token: $token, type: $type');
      final response = await supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: type,
      );
      return response;
    } catch (e) {
      dev.log('Error verifying OTP: $e');
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
      dev.log('Resending OTP to: $email, type: $type');
      if (type == OtpType.recovery) {
        await sendPasswordResetEmail(email);
      } else {
        await supabase.auth.resend(
          email: email,
          type: type,
        );
      }
    } catch (e) {
      dev.log('Error resending OTP: $e');
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
}

// Notifier for GoRouter to listen to auth changes
class AuthNotifier extends ChangeNotifier {
  AuthNotifier(Ref ref) {
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