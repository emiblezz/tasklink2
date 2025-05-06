import 'package:supabase/supabase.dart';
import 'package:tasklink2/config/app_config.dart';
import 'package:tasklink2/models/user_model.dart';
import 'package:tasklink2/models/role_model.dart';
import 'package:tasklink2/models/jobseeker_profile_model.dart';

class SupabaseService {
  // Use Supabase.instance.client instead of AppConfig().supabaseClient
  final SupabaseClient _supabaseClient = AppConfig().supabaseClient;
  SupabaseClient get supabaseClient => _supabaseClient;

  // Getter for external access if needed
  SupabaseClient get supabase => _supabaseClient;

  // Get the current authenticated user
  Future<UserModel?> getCurrentUser() async {
    try {
      final authUser = _supabaseClient.auth.currentSession?.user;
      if (authUser == null) return null;

      final response = await _supabaseClient
          .from('users')
          .select()
          .eq('user_id', authUser.id)
          .maybeSingle();

      if (response == null) {
        print('User not found with user_id=${authUser.id}');
        return null;
      }

      return UserModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      // First, let's print the userId we're searching for
      print('Searching for user with ID: $userId');

      // Try with user_id column first
      try {
        final response = await _supabaseClient
            .from('users')
            .select()
            .eq('user_id', userId)
            .maybeSingle(); // Use maybeSingle instead of single

        if (response != null) {
          print('Found user using user_id column');
          return UserModel.fromJson(response);
        }
      } catch (innerError) {
        print('Error with user_id query: $innerError');
      }

      // If not found with user_id, try with id
      try {
        final response = await _supabaseClient
            .from('users')
            .select()
            .eq('user_id', userId)
            .maybeSingle(); // Use maybeSingle instead of single

        if (response != null) {
          print('Found user using id column');
          return UserModel.fromJson(response);
        }
      } catch (innerError) {
        print('Error with id query: $innerError');
      }

      print('No user found with either column name for ID: $userId');
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  // Get job seeker profile
  Future<JobSeekerProfileModel?> getJobSeekerProfile(String userId) async {
    try {
      final response = await _supabaseClient
          .from('jobseeker_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        return JobSeekerProfileModel.fromJson(response as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting job seeker profile: $e');
      return null;
    }
  }

  // Get all roles
  Future<List<RoleModel>> getAllRoles() async {
    try {
      final response = await _supabaseClient
          .from('roles')
          .select()
          .order('role_id');

      return (response as List)
          .map((role) => RoleModel.fromJson(role))
          .toList();
    } catch (e) {
      print('Error getting roles: $e');
      return [];
    }
  }

  // Create or update a user
  Future<UserModel?> createOrUpdateUser(UserModel user) async {
    try {
      final jsonData = user.toJson();
      print('Upserting user data: $jsonData');

      final response = await _supabaseClient
          .from('users')
          .upsert(jsonData)
          .select()
          .maybeSingle();

      if (response == null) {
        print('No response after upsert');
        return null;
      }

      print('Upsert response: $response');
      return UserModel.fromJson(response);
    } catch (e) {
      print('Error creating/updating user: $e');
      return null;
    }
  }

  // Delete a user
  Future<bool> deleteUser(String userId) async {
    try {
      await _supabaseClient
          .from('users')
          .delete()
          .eq('user_id', userId);
      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  // Add this method to your SupabaseService class
  Future<List<Map<String, dynamic>>> getJobApplicationsWithProfiles(int jobId) async {
    try {
      print('Fetching applications for job ID: $jobId using simple query');

      // Simple query to get all applications for the job
      final applications = await _supabaseClient
          .from('applications')
          .select('*')
          .eq('job_id', jobId);

      print('Basic applications query result length: ${applications.length}');
      print('First few applications: ${applications.take(2)}');

      // Convert the results to the expected format
      final List<Map<String, dynamic>> result = [];

      for (var app in applications) {
        // Add each application to the result list
        result.add(app);
      }

      return result;
    } catch (e) {
      print('Error getting applications: $e');
      return [];
    }
  }

// Get job applications with user profiles - Improved version with join
}