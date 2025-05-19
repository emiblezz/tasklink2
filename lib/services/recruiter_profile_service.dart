import 'package:flutter/foundation.dart';
import 'package:supabase/supabase.dart';
import 'package:tasklink2/config/app_config.dart';
import 'package:tasklink2/models/recruiter_profile_model.dart';
import 'package:tasklink2/services/image_picker_service.dart';

class RecruiterProfileService with ChangeNotifier {
  final SupabaseClient _supabaseClient = AppConfig().supabaseClient;

  RecruiterProfileModel? _recruiterProfile;
  bool _isLoading = false;
  String? _errorMessage;

  RecruiterProfileModel? get recruiterProfile => _recruiterProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fetch recruiter profile
  Future<RecruiterProfileModel?> fetchProfile(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabaseClient
          .from('recruiter_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        _recruiterProfile = RecruiterProfileModel.fromJson(response);
      } else {
        _recruiterProfile = null;
      }

      _isLoading = false;
      notifyListeners();
      return _recruiterProfile;
    } catch (e) {
      _errorMessage = 'Failed to fetch profile: ${e.toString()}';
      debugPrint(_errorMessage);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Save recruiter profile
  Future<RecruiterProfileModel?> saveProfile(RecruiterProfileModel profile) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if profile already exists
      final existingProfile = await _supabaseClient
          .from('recruiter_profiles')
          .select()
          .eq('user_id', profile.userId)
          .maybeSingle();

      late final dynamic result;
      // Update or insert based on whether profile exists
      if (existingProfile != null) {
        result = await _supabaseClient
            .from('recruiter_profiles')
            .update(profile.toJson())
            .eq('user_id', profile.userId)
            .select()
            .single();
      } else {
        result = await _supabaseClient
            .from('recruiter_profiles')
            .insert(profile.toJson())
            .select()
            .single();
      }

      _recruiterProfile = RecruiterProfileModel.fromJson(result);

      // Update user profile status
      await _updateUserProfileStatus(profile.userId, 'Complete');

      _isLoading = false;
      notifyListeners();
      return _recruiterProfile;
    } catch (e) {
      _errorMessage = 'Failed to save profile: ${e.toString()}';
      debugPrint(_errorMessage);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Upload company logo using your existing ImagePickerService
  Future<String?> pickAndUploadLogo(String userId) async {
    try {
      // Use your existing image picker service
      final logoUrl = await ImagePickerService.pickCompanyLogo();
      return logoUrl;
    } catch (e) {
      _errorMessage = 'Failed to upload logo: ${e.toString()}';
      debugPrint(_errorMessage);
      notifyListeners();
      return null;
    }
  }

  // Helper method to update user's profile status
  Future<void> _updateUserProfileStatus(String userId, String status) async {
    try {
      await _supabaseClient
          .from('users')
          .update({'profile_status': status})
          .eq('id', userId);
    } catch (e) {
      debugPrint('Failed to update profile status: ${e.toString()}');
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}