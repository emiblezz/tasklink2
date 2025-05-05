import 'package:flutter/foundation.dart';
import 'package:supabase/supabase.dart';
import 'package:tasklink2/config/app_config.dart';
import 'package:tasklink2/models/job_model.dart';
import 'package:tasklink2/models/application_model.dart';
import 'package:tasklink2/services/auth_service.dart';
import 'package:tasklink2/services/notification_service.dart';

class JobService extends ChangeNotifier {
  final SupabaseClient _supabaseClient = AppConfig().supabaseClient;
  AuthService? _authService;
  NotificationService? _notificationService;

  List<JobModel> _jobs = [];
  List<ApplicationModel> _applications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<JobModel> get jobs => _jobs;
  List<ApplicationModel> get applications => _applications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Allow setting services from outside
  void setAuthService(AuthService authService) {
    _authService = authService;
  }

  void setNotificationService(NotificationService notificationService) {
    _notificationService = notificationService;
  }

  // Get all jobs
  Future<void> fetchJobs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Fetching all open jobs');
      final response = await _supabaseClient
          .from('job_postings')
          .select()
          .eq('status', 'Open')
          .order('date_posted', ascending: false);

      _jobs = (response as List).map((job) => JobModel.fromJson(job)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching jobs: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get recruiter's jobs
  Future<void> fetchRecruiterJobs(String recruiterId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Fetching jobs for recruiter: $recruiterId');
      final response = await _supabaseClient
          .from('job_postings')
          .select()
          .eq('recruiter_id', recruiterId)
          .order('date_posted', ascending: false);

      _jobs = (response as List).map((job) => JobModel.fromJson(job)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching recruiter jobs: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get job by ID
  Future<JobModel?> getJobById(int jobId) async {
    try {
      debugPrint('Getting job with ID: $jobId');
      final response = await _supabaseClient
          .from('job_postings')
          .select()
          .eq('job_id', jobId)
          .single();

      return JobModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error getting job by ID: $e');
      _errorMessage = e.toString();
      return null;
    }
  }

  // Create a new job
  Future<JobModel?> createJob(JobModel job) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Creating new job: ${job.jobTitle}');
      final response = await _supabaseClient
          .from('job_postings')
          .insert(job.toJson())
          .select()
          .single();

      final newJob = JobModel.fromJson(response as Map<String, dynamic>);
      _jobs.add(newJob);

      // Send notifications if the service is available
      if (_notificationService != null && _authService != null && _authService!.currentUser != null) {
        try {
          // Get job seekers - this is simplified and would need to be replaced
          // with your actual implementation to fetch job seekers
          List<String> jobSeekerIds = await _getJobSeekerIds();

          await _notificationService!.notifyNewJob(
            jobSeekerIds: jobSeekerIds,
            jobTitle: newJob.jobTitle,
            companyName: _authService!.currentUser!.name,
          );
        } catch (notificationError) {
          debugPrint('Error sending job notifications: $notificationError');
          // Continue execution even if notifications fail
        }
      }

      _isLoading = false;
      notifyListeners();
      return newJob;
    } catch (e) {
      debugPrint('Error creating job: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Helper method to get job seeker IDs
  Future<List<String>> _getJobSeekerIds() async {
    try {
      debugPrint('Fetching job seeker IDs');
      // Example implementation - replace with your actual query
      final response = await _supabaseClient
          .from('users')
          .select('user_id')
          .eq('role_id', 1) // Assuming 1 is the job seeker role ID
          .limit(20); // Limit to avoid notifying too many users

      return (response as List).map((user) => user['user_id'] as String).toList();
    } catch (e) {
      debugPrint('Error fetching job seeker IDs: $e');
      return [];
    }
  }

  // Update job
  Future<JobModel?> updateJob(JobModel job) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Updating job ID: ${job.id}, title: ${job.jobTitle}');
      final response = await _supabaseClient
          .from('job_postings')
          .update(job.toJson())
          .eq('job_id', job.id)
          .select()
          .single();

      final updatedJob = JobModel.fromJson(response as Map<String, dynamic>);

      // Update the job in the list
      final index = _jobs.indexWhere((j) => j.id == job.id);
      if (index != -1) {
        _jobs[index] = updatedJob;
      }

      _isLoading = false;
      notifyListeners();
      return updatedJob;
    } catch (e) {
      debugPrint('Error updating job: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Close a job
  Future<bool> closeJob(int jobId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Closing job ID: $jobId');
      await _supabaseClient
          .from('job_postings')
          .update({'status': 'Closed'})
          .eq('job_id', jobId);

      // Update the job in the list
      final index = _jobs.indexWhere((j) => j.id == jobId);
      if (index != -1) {
        _jobs[index] = _jobs[index].copyWith(status: 'Closed');
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error closing job: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Apply for a job
  Future<ApplicationModel?> applyForJob(int jobId, String applicantId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Applying for job ID: $jobId, applicant: $applicantId');
      final application = ApplicationModel(
        jobId: jobId,
        applicantId: applicantId,
        dateApplied: DateTime.now(),
      );

      final response = await _supabaseClient
          .from('applications')
          .insert(application.toJson())
          .select()
          .single();

      final newApplication = ApplicationModel.fromJson(response as Map<String, dynamic>);
      _applications.add(newApplication);

      // Send notification if services are available
      if (_notificationService != null) {
        try {
          debugPrint('Getting job details for notification');
          final job = await getJobById(jobId);
          if (job != null) {
            String applicantName = "A candidate";

            if (_authService != null && _authService!.currentUser != null) {
              applicantName = _authService!.currentUser!.name;
            } else {
              // Fallback to get applicant name
              try {
                final userResponse = await _supabaseClient
                    .from('users')
                    .select('name')
                    .eq('user_id', applicantId)
                    .single();

                if (userResponse != null && userResponse['name'] != null) {
                  applicantName = userResponse['name'];
                }
              } catch (e) {
                debugPrint('Error getting applicant name: $e');
              }
            }

            debugPrint('Sending application notification to recruiter: ${job.recruiterId}');
            await _notificationService!.notifyJobApplication(
              recruiterId: job.recruiterId,
              jobTitle: job.jobTitle,
              applicantName: applicantName,
            );
          }
        } catch (notificationError) {
          debugPrint('Error sending application notification: $notificationError');
          // Continue execution even if notification fails
        }
      }

      _isLoading = false;
      notifyListeners();
      return newApplication;
    } catch (e) {
      debugPrint('Error applying for job: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Get user applications
  Future<void> fetchUserApplications(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Fetching applications for user: $userId');
      final response = await _supabaseClient
          .from('applications')
          .select()
          .eq('applicant_id', userId)
          .order('date_applied', ascending: false);

      _applications = (response as List).map((app) => ApplicationModel.fromJson(app)).toList();
      debugPrint('Found ${_applications.length} applications for user');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching user applications: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get applications for a job
  Future<List<ApplicationModel>> getJobApplications(int jobId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Fetching applications for job ID: $jobId');
      final response = await _supabaseClient
          .from('applications')
          .select()
          .eq('job_id', jobId);

      if (response is List) {
        final applications = response.map((app) => ApplicationModel.fromJson(app)).toList();
        debugPrint('Found ${applications.length} applications for job');
        _isLoading = false;
        notifyListeners();
        return applications;
      } else {
        debugPrint('Unexpected response format from applications query');
        _isLoading = false;
        notifyListeners();
        return [];
      }
    } catch (e) {
      debugPrint('Error getting job applications: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  // Get application by ID
  Future<ApplicationModel?> getApplicationById(int applicationId) async {
    try {
      debugPrint('Getting application with ID: $applicationId');
      final response = await _supabaseClient
          .from('applications')
          .select()
          .eq('application_id', applicationId)
          .single();

      return ApplicationModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error getting application by ID: $e');
      _errorMessage = e.toString();
      return null;
    }
  }

  // Update application status
  // In JobService.dart
  Future<bool> updateApplicationStatus(int applicationId, String status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Updating application ID: $applicationId to status: $status');

      // Validate the status value
      final validStatuses = ['Pending', 'Reviewing', 'Rejected', 'Selected'];
      if (!validStatuses.contains(status)) {
        throw Exception('Invalid status: $status. Must be one of: ${validStatuses.join(', ')}');
      }

      // First, check column name in applications table
      debugPrint('Attempting to update application status in database');

      try {
        // Try with 'status' column name
        await _supabaseClient
            .from('applications')
            .update({'status': status})
            .eq('id', applicationId);

        debugPrint('Successfully updated with "status" column');
      } catch (e) {
        debugPrint('First attempt failed, trying with different column name: $e');

        try {
          // Try with 'application_status' column name
          await _supabaseClient
              .from('applications')
              .update({'application_status': status})
              .eq('application_id', applicationId);

          debugPrint('Successfully updated with "application_status" column');
        } catch (e2) {
          debugPrint('Second attempt failed, trying one more configuration: $e2');

          // Try with different primary key name
          await _supabaseClient
              .from('applications')
              .update({'status': status})
              .eq('application_id', applicationId);

          debugPrint('Successfully updated with "application_id" as primary key');
        }
      }

      // Update the application in the list
      final index = _applications.indexWhere((a) => a.id == applicationId);
      if (index != -1) {
        _applications[index] = _applications[index].copyWith(applicationStatus: status);
      }

      // Handle notifications (same as your current code)
      if (_notificationService != null) {
        try {
          final application = await getApplicationById(applicationId);
          if (application != null) {
            final job = await getJobById(application.jobId);
            if (job != null) {
              await _notificationService!.notifyStatusChange(
                applicantId: application.applicantId,
                jobTitle: job.jobTitle,
                status: status,
              );
            }
          }
        } catch (e) {
          debugPrint('Error sending notification: $e');
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating application status: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Search jobs
  // In JobService.dart
  Future<List<JobModel>> searchJobs(String query) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Searching jobs with query: "${query.trim()}"');

      if (query.trim().isEmpty) {
        // If empty query, return all jobs
        await fetchJobs();
        _isLoading = false;
        notifyListeners();
        return _jobs;
      }

      // Sanitize query for Supabase - prepare search pattern
      final searchPattern = '%${query.trim().toLowerCase()}%';

      final response = await _supabaseClient
          .from('job_postings')
          .select()
          .eq('status', 'Open')
          .or('job_title.ilike.$searchPattern,description.ilike.$searchPattern,company_name.ilike.$searchPattern,job_type.ilike.$searchPattern,location.ilike.$searchPattern')
          .order('date_posted', ascending: false);

      debugPrint('Search found ${response.length} results');

      final results = (response as List)
          .map((job) => JobModel.fromJson(job))
          .toList();

      _isLoading = false;
      notifyListeners();
      return results;
    } catch (e) {
      debugPrint('Error searching jobs: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }


  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

}