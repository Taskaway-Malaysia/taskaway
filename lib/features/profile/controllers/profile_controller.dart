import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskaway/features/auth/models/profile.dart';
import 'dart:developer' as dev;

/// Provider for profile controller
final profileControllerProvider = Provider<ProfileController>((ref) {
  return ProfileController(supabase: Supabase.instance.client);
});

/// Controller for handling profile-related operations
class ProfileController {
  final SupabaseClient supabase;

  ProfileController({required this.supabase});

  /// Updates a user's profile with the given data
  Future<Profile?> updateProfile({
    required String userId,
    String? fullName,
    String? role,
    String? phone,
    String? avatarUrl,
    DateTime? dateOfBirth,
    int? postcode,
  }) async {
    try {
      // Create a map of non-null values to update
      final Map<String, dynamic> updateData = {};
      if (fullName != null) updateData['full_name'] = fullName;
      if (role != null) updateData['role'] = role;
      if (phone != null) updateData['phone'] = phone;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
      if (dateOfBirth != null) updateData['date_of_birth'] = dateOfBirth.toIso8601String();
      if (postcode != null) updateData['postcode'] = postcode;
      
      // Add updated_at timestamp
      updateData['updated_at'] = DateTime.now().toIso8601String();
      
      // Update the profile in Supabase
      final data = await supabase
          .from('taskaway_profiles')
          .update(updateData)
          .eq('id', userId)
          .select()
          .single();
      
      dev.log('Profile updated successfully: $data');
      return Profile.fromJson(data);
    } catch (e) {
      dev.log('Error updating profile', error: e);
      return null;
    }
  }

  /// Updates only the user's role in the profile
  Future<bool> updateUserRole({
    required String userId,
    required String role,
  }) async {
    try {
      // Convert UI role format to database format
      final String dbRole = role == 'As Poster' ? 'poster' : 'tasker';
      
      // Update only the role field
      await supabase
          .from('taskaway_profiles')
          .update({
            'role': dbRole,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      
      dev.log('User role updated successfully to: $dbRole');
      return true;
    } catch (e) {
      dev.log('Error updating user role', error: e);
      return false;
    }
  }
}
