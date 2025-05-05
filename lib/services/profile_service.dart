import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';
import 'package:tasklink2/config/app_config.dart';
import 'package:tasklink2/models/jobseeker_profile_model.dart';
import 'package:tasklink2/services/file_service.dart';
import 'package:path/path.dart' as path;

class ProfileService extends ChangeNotifier {
  // Initialize directly to avoid LateInitializationError
  final SupabaseClient _supabaseClient = AppConfig().supabaseClient;
  JobSeekerProfileModel? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  JobSeekerProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fetch profile data
  Future<JobSeekerProfileModel?> fetchProfile(String userId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // First check if user exists in users table
      final userResponse = await _supabaseClient
          .from('users')
          .select()
          .eq('user_id', userId)
          .single();

      if (userResponse == null) {
        _errorMessage = 'User profile not found';
        _setLoading(false);
        return null;
      }

      // Then check if jobseeker profile exists
      final response = await _supabaseClient
          .from('jobseeker_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        _profile = JobSeekerProfileModel.fromJson(response);
        _setLoading(false);
        return _profile;
      } else {
        // Profile doesn't exist yet, return an empty profile
        _profile = JobSeekerProfileModel(
          userId: userId,
          cv: null,
          skills: '',
          experience: '',
          education: '',
          linkedinProfile: '',
        );
        _setLoading(false);
        return _profile;
      }
    } catch (e) {
      _errorMessage = 'Error fetching profile: ${e.toString()}';
      _setLoading(false);
      return null;
    }
  }

  // Save or update profile
  Future<JobSeekerProfileModel?> saveProfile(JobSeekerProfileModel profile) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // First check if profile exists
      final exists = await _profileExists(profile.userId);

      if (exists) {
        // Update existing profile
        await _supabaseClient
            .from('jobseeker_profiles')
            .update({
          'cv': profile.cv,
          'skills': profile.skills,
          'experience': profile.experience,
          'education': profile.education,
          'linkedin_profile': profile.linkedinProfile,
        })
            .eq('user_id', profile.userId);
      } else {
        // Create new profile
        await _supabaseClient
            .from('jobseeker_profiles')
            .insert({
          'user_id': profile.userId,
          'cv': profile.cv,
          'skills': profile.skills,
          'experience': profile.experience,
          'education': profile.education,
          'linkedin_profile': profile.linkedinProfile,
        });
      }

      // Fetch the updated profile
      final updatedProfile = await fetchProfile(profile.userId);
      _setLoading(false);
      return updatedProfile;
    } catch (e) {
      _errorMessage = 'Error saving profile: ${e.toString()}';
      _setLoading(false);
      return null;
    }
  }

  // Check if profile exists
  Future<bool> _profileExists(String userId) async {
    try {
      final response = await _supabaseClient
          .from('jobseeker_profiles')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking if profile exists: ${e.toString()}');
      return false;
    }
  }

  // Method to pick and upload CV
  Future<String?> pickAndUploadCV(String userId) async {
    _errorMessage = null;

    try {
      // Use the file picker
      final cvUrl = await FileService.pickCV();

      if (cvUrl == null) {
        _errorMessage = 'File selection cancelled';
        notifyListeners();
        return null;
      }

      debugPrint('CV URL from FileService: $cvUrl');

      // Check if profile exists
      final exists = await _profileExists(userId);

      try {
        if (exists) {
          // Update only the CV field
          debugPrint('Updating existing profile with CV: $cvUrl');
          await _supabaseClient
              .from('jobseeker_profiles')
              .update({'cv': cvUrl})
              .eq('user_id', userId);
        } else {
          // Insert new profile with default values
          debugPrint('Creating new profile with CV: $cvUrl');
          await _supabaseClient
              .from('jobseeker_profiles')
              .insert({
            'user_id': userId,
            'cv': cvUrl,
            'skills': '',
            'experience': '',
            'education': '',
            'linkedin_profile': '',
          });
        }

        // Update the local profile
        if (_profile != null) {
          _profile = _profile!.copyWith(cv: cvUrl);
        } else {
          _profile = JobSeekerProfileModel(
            userId: userId,
            cv: cvUrl,
            skills: '',
            experience: '',
            education: '',
            linkedinProfile: '',
          );
        }
        notifyListeners();

        return cvUrl;
      } catch (dbError) {
        debugPrint('Database error during CV update: $dbError');
        _errorMessage = 'Database error: ${dbError.toString()}';
        notifyListeners();
        return cvUrl; // Still return the URL even if DB update fails
      }
    } catch (e) {
      _errorMessage = 'Error uploading CV: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  // Helper method to determine content type from file name
  String _getContentType(String fileName) {
    if (fileName.toLowerCase().endsWith('.pdf')) {
      return 'application/pdf';
    } else if (fileName.toLowerCase().endsWith('.doc')) {
      return 'application/msword';
    } else if (fileName.toLowerCase().endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    } else if (fileName.toLowerCase().endsWith('.txt')) {
      return 'text/plain';
    }
    // Default
    return 'application/octet-stream';
  }

  // Helper to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}