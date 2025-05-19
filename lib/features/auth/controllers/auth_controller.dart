import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authControllerProvider = StateNotifierProvider<AuthController, bool>((ref) {
  return AuthController(
    supabase: Supabase.instance.client,
  );
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

class AuthController extends StateNotifier<bool> {
  final SupabaseClient supabase;

  AuthController({required this.supabase}) : super(false);

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    state = true;
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: data,
      );
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
      return response;
    } finally {
      state = false;
    }
  }

  Future<void> signOut() async {
    state = true;
    try {
      await supabase.auth.signOut();
    } finally {
      state = false;
    }
  }

  Future<void> resetPassword(String email) async {
    state = true;
    try {
      await supabase.auth.resetPasswordForEmail(email);
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