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
    String? bio,
    String? about,
    List<String>? skills,
    List<String>? myWorks,
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
      if (bio != null) updateData['bio'] = bio;
      if (about != null) updateData['about'] = about;
      if (skills != null) updateData['skills'] = skills;
      if (myWorks != null) updateData['my_works'] = myWorks;
      
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

  /// Updates only the user's skills
  Future<Profile?> updateSkills({
    required String userId,
    required List<String> skills,
  }) async {
    try {
      dev.log('Updating skills for user $userId: $skills');
      
      final data = await supabase
          .from('taskaway_profiles')
          .update({
            'skills': skills,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId)
          .select()
          .single();
      
      dev.log('Skills updated successfully: $data');
      return Profile.fromJson(data);
    } catch (e) {
      dev.log('Error updating skills', error: e);
      return null;
    }
  }

  /// Updates only the user's works
  Future<Profile?> updateWorks({
    required String userId,
    required List<String> workUrls,
  }) async {
    try {
      dev.log('Updating works for user $userId: $workUrls');
      
      final data = await supabase
          .from('taskaway_profiles')
          .update({
            'my_works': workUrls,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId)
          .select()
          .single();
      
      dev.log('Works updated successfully: $data');
      return Profile.fromJson(data);
    } catch (e) {
      dev.log('Error updating works', error: e);
      return null;
    }
  }

  /// Deletes a work image from storage and updates the profile
  Future<bool> deleteWorkImage({
    required String userId,
    required String imageUrl,
  }) async {
    try {
      dev.log('Deleting work image: $imageUrl');
      
      // First get current works
      final currentProfile = await supabase
          .from('taskaway_profiles')
          .select('my_works')
          .eq('id', userId)
          .single();
      
      final currentWorks = currentProfile['my_works'] as List<dynamic>?;
      if (currentWorks == null) return false;
      
      // Remove the image URL from the list
      final updatedWorks = List<String>.from(currentWorks)
        ..remove(imageUrl);
      
      // Update the profile
      await supabase
          .from('taskaway_profiles')
          .update({
            'my_works': updatedWorks,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      
      // Extract file path from URL and delete from storage
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 3) {
        final filePath = pathSegments.sublist(2).join('/'); // Skip 'storage/v1/object/public/bucket-name'
        await supabase.storage.from('task-images').remove([filePath]);
      }
      
      dev.log('Work image deleted successfully');
      return true;
    } catch (e) {
      dev.log('Error deleting work image', error: e);
      return false;
    }
  }
}
