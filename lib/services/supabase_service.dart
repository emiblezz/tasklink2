import 'dart:io';
import 'dart:math' as Math;

import 'package:flutter/cupertino.dart';
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
  Future<String?> uploadCompanyLogo(File imageFile, String companyName) async {
    try {
      final fileName = '${companyName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = 'company_logos/$fileName';

      // Define bucket name - use "public" as it's a common default bucket
      const bucketName = 'public';

      // Check if bucket exists
      try {
        // Try to get bucket info (this will throw an error if it doesn't exist)
        await _supabaseClient.storage.getBucket(bucketName);
        debugPrint('Bucket $bucketName exists');
      } catch (e) {
        debugPrint('Bucket $bucketName might not exist: $e');

        // Try to create the bucket
        try {
          await _supabaseClient.storage.createBucket(bucketName,
              const BucketOptions(public: true));
          debugPrint('Created bucket $bucketName');
        } catch (createError) {
          debugPrint('Error creating bucket: $createError');
          // Continue anyway - the bucket might already exist
        }
      }

      // Upload to Supabase storage
      try {
        await _supabaseClient
            .storage
            .from(bucketName)
            .upload(filePath, imageFile);

        // If we get here, the upload was successful
        debugPrint('Logo uploaded successfully to $bucketName/$filePath');

        // Get the public URL
        final urlResponse = await _supabaseClient
            .storage
            .from(bucketName)
            .getPublicUrl(filePath);

        return urlResponse;
      } catch (uploadError) {
        // Handle upload error
        debugPrint('Error uploading company logo: $uploadError');
        return null;
      }
    } catch (e) {
      debugPrint('Exception uploading company logo: $e');
      return null;
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      debugPrint('Getting user by ID: $userId');

      // Try with user_id from users table
      final userData = await _supabaseClient
          .from('users')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (userData != null) {
        debugPrint('Found user data: ${userData['name']}');
        return UserModel.fromJson(userData);
      }

      // Create a deterministic but somewhat personalized fallback
      // Use parts of the UUID to create a unique identifier
      String shortId = '';
      if (userId.contains('-')) {
        final parts = userId.split('-');
        if (parts.length > 1) {
          shortId = parts[0].substring(0, 4);
        } else {
          shortId = userId.substring(0, 4);
        }
      } else {
        shortId = userId.substring(0, Math.min(4, userId.length));
      }

      return UserModel(
        id: userId,
        name: 'Applicant ' + shortId,
        email: 'applicant-' + shortId + '@example.com',
        phone: '',
        roleId: 1, // 1 = jobseeker
        profileStatus: 'Active',
      );
    } catch (e) {
      debugPrint('Error getting user by ID: $e');

      // Simple fallback
      return UserModel(
        id: userId,
        name: 'Applicant',
        email: 'applicant@example.com',
        phone: '',
        roleId: 1,
        profileStatus: 'Active',
      );
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

  /// Fetches the most recent resume for a user by their ID
  /// Fetches the most recent resume for a user by their ID
  /// Fetches the most recent resume for a user by their ID
  /// Fetches the most recent resume for a user by their ID
  Future<Map<String, dynamic>?> getUserResume(String userId) async {
    try {
      debugPrint('Getting resume for user ID: $userId');

      // Query the resumes table for the most recent resume
      final resumeData = await _supabaseClient
          .from('resumes')
          .select('resume_id, applicant_id, text, uploaded_date, filename')
          .eq('applicant_id', userId)
          .order('uploaded_date', ascending: false) // Get the most recent resume
          .limit(1)
          .maybeSingle();

      if (resumeData == null) {
        debugPrint('No resume found for user ID: $userId');
        return null;
      }

      debugPrint('Found resume: ${resumeData['resume_id']} - ${resumeData['filename']}');

      // Also get the CV URL from the jobseeker profile
      String? cvUrl;
      try {
        final profileData = await _supabaseClient
            .from('jobseeker_profiles')
            .select('cv')
            .eq('user_id', userId)
            .maybeSingle();

        if (profileData != null && profileData['cv'] != null) {
          cvUrl = profileData['cv'] as String?;
          debugPrint('Found CV URL in profile: $cvUrl');
        }
      } catch (e) {
        debugPrint('Error getting CV URL from profile: $e');
      }

      // Return the resume data along with the CV URL
      return {
        'resume_id': resumeData['resume_id'],
        'applicant_id': resumeData['applicant_id'],
        'text': resumeData['text'],
        'uploaded_date': resumeData['uploaded_date'],
        'filename': resumeData['filename'],
        'cv_url': cvUrl,
      };
    } catch (e) {
      debugPrint('Error fetching resume: $e');
      return null;
    }
  }

  /// Fetches the jobseeker profile for a given user ID
  Future<Map<String, dynamic>?> getJobseekerProfile(String userId) async {
    try {
      // Query by user_id (not profile_id)
      final response = await supabaseClient
          .from('jobseeker_profiles')
          .select('*')
          .eq('user_id', userId)  // Changed from profile_id to user_id
          .maybeSingle();  // Use maybeSingle instead of single to avoid errors if no profile exists

      if (response == null) {
        debugPrint('No jobseeker profile found for user ID: $userId');
        return null;
      }

      debugPrint('Found jobseeker profile: ${response['profile_id']}');
      return response;
    } catch (e) {
      debugPrint('Error fetching jobseeker profile: $e');
      return null;
    }
  }
  // Add this method to your SupabaseService class

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
  Future<Map<String, dynamic>?> getJobseekerProfileData(String userId) async {
    try {
      final response = await _supabaseClient
          .from('jobseeker_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error fetching jobseeker profile data: $e');
      return null;
    }
  }
  // Add this method to your SupabaseService class to handle saving feedback

  Future<bool> saveRecruiterFeedback(int applicationId, String feedback) async {
    try {
      debugPrint('Saving feedback for application ID: $applicationId');

      // First get the application details for notification
      final appDetails = await _supabaseClient
          .from('applications')
          .select('applicant_id, job_id')
          .eq('application_id', applicationId)
          .maybeSingle();

      if (appDetails == null) {
        debugPrint('Application not found with ID: $applicationId');
        return false;
      }

      // Update the application with the feedback
      await _supabaseClient
          .from('applications')
          .update({
        'recruiter_feedback': feedback,
        'last_updated': DateTime.now().toIso8601String(),
      })
          .eq('application_id', applicationId);

      // Create notification for the applicant about the feedback
      if (appDetails['applicant_id'] != null) {
        // Get job details for the notification
        final jobDetails = await _supabaseClient
            .from('jobs')
            .select('job_title')
            .eq('job_id', appDetails['job_id'])
            .maybeSingle();

        String jobTitle = 'a job';
        if (jobDetails != null && jobDetails['job_title'] != null) {
          jobTitle = jobDetails['job_title'];
        }

        try {
          // Create notification
          await _supabaseClient
              .from('notifications')
              .insert({
            'user_id': appDetails['applicant_id'],
            'notification_type': 'recruiter_feedback',
            'notification_message': 'You\'ve received feedback on your application for "$jobTitle"',
            'status': 'Unread',
            'timestamp': DateTime.now().toIso8601String(),
            'data': '{"job_id":"${appDetails['job_id']}","application_id":"$applicationId"}'
          });

          debugPrint('Feedback notification created for applicant');
        } catch (notificationError) {
          debugPrint('Error creating feedback notification: $notificationError');
          // Continue even if notification creation fails
        }
      }

      debugPrint('Feedback saved successfully');
      return true;
    } catch (e) {
      debugPrint('Error saving feedback: $e');
      return false;
    }
  }
  // Add this method to your SupabaseService class to handle application status updates

  // Add this method to your SupabaseService class to handle application status updates

  Future<bool> updateApplicationStatus(int applicationId, String status) async {
    try {
      debugPrint('Updating application $applicationId status to: $status');

      // First get the application details for notification
      final appDetails = await _supabaseClient
          .from('applications')
          .select('applicant_id, job_id')
          .eq('application_id', applicationId)
          .maybeSingle();

      if (appDetails == null) {
        debugPrint('Application not found with ID: $applicationId');
        return false;
      }

      // Update the application status
      await _supabaseClient
          .from('applications')
          .update({
        'application_status': status,
        'status_updated_at': DateTime.now().toIso8601String(),
      })
          .eq('application_id', applicationId);

      // Create notification for the applicant
      if (appDetails['applicant_id'] != null) {
        // Get job details for the notification
        final jobDetails = await _supabaseClient
            .from('jobs')
            .select('job_title')
            .eq('job_id', appDetails['job_id'])
            .maybeSingle();

        String jobTitle = 'a job';
        if (jobDetails != null && jobDetails['job_title'] != null) {
          jobTitle = jobDetails['job_title'];
        }

        try {
          // Create notification
          await _supabaseClient
              .from('notifications')
              .insert({
            'user_id': appDetails['applicant_id'],
            'notification_type': 'application_update',
            'notification_message': 'Your application for "$jobTitle" has been updated to $status.',
            'status': 'Unread',
            'timestamp': DateTime.now().toIso8601String(),
            'data': '{"job_id":"${appDetails['job_id']}","status":"$status","application_id":"$applicationId"}'
          });

          debugPrint('Notification created for applicant');
        } catch (notificationError) {
          debugPrint('Error creating notification: $notificationError');
          // Continue even if notification creation fails
        }
      }

      debugPrint('Application status updated successfully');
      return true;
    } catch (e) {
      debugPrint('Error updating application status: $e');
      return false;
    }
  }

// Get job applications with user profiles - Improved version with join
}