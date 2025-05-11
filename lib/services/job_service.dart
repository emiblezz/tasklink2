import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase/supabase.dart';
import 'package:tasklink2/config/app_config.dart';
import 'package:tasklink2/models/application_model.dart';
import 'package:tasklink2/models/job_model.dart';

import 'auth_service.dart';
import 'notification_service.dart';

class JobService with ChangeNotifier {
  final SupabaseClient _supabaseClient = AppConfig().supabaseClient;
  bool _isLoading = false;
  String? _errorMessage;
  List<JobModel> _jobs = [];
  List<ApplicationModel> _applications = [];
  Set<int> _dismissedJobIds = {}; // Added for job dismissal functionality
  DateTime _lastDismissedJobsLoadTime = DateTime.now();
  String? _statusFilter;
  Set<int> get dismissedJobIds => _dismissedJobIds;
  // Getters
  AuthService? _authService;
  NotificationService? _notificationService;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<JobModel> get jobs => _jobs;
  List<ApplicationModel> get applications => _applications;
  String? get statusFilter => _statusFilter;

  // Getter for filtered jobs based on status
  List<JobModel> get recruiterJobs {
    if (_statusFilter == null) {
      return _jobs;
    }
    return _jobs.where((job) => job.status == _statusFilter).toList();
  }

  // Getter for visible jobs (not dismissed and not expired)
  List<JobModel> get visibleJobs {
    final now = DateTime.now();
    return _jobs.where((job) =>
    !_dismissedJobIds.contains(job.id) &&
        job.deadline.isAfter(now) &&
        job.status == 'Open'
    ).toList();
  }

  // Constructor - load dismissed jobs
  JobService() {
    loadDismissedJobs();
  }

  // Set status filter
  void setStatusFilter(String? filter) {
    _statusFilter = filter;
    notifyListeners();
  }
  void setAuthService(AuthService authService) {
    _authService = authService;
  }

  void setNotificationService(NotificationService notificationService) {
    _notificationService = notificationService;
  }

  // Fetch all jobs
  Future<List<JobModel>> fetchJobs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabaseClient
          .from('job_postings')
          .select()
          .eq('status', 'Open')
          .order('date_posted', ascending: false);

      _jobs = (response as List).map((job) => JobModel.fromJson(job)).toList();

      // Load dismissed jobs if not loaded in the last hour
      if (DateTime.now().difference(_lastDismissedJobsLoadTime).inHours >= 1) {
        await loadDismissedJobs();
      }

      _isLoading = false;
      notifyListeners();
      return _jobs;
    } catch (e) {
      debugPrint('Error fetching jobs: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  // Fetch jobs posted by a specific recruiter
  // Update the fetchRecruiterJobs method to handle nullable recruiterId
  Future<List<JobModel>> fetchRecruiterJobs(String? recruiterId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (recruiterId == null) {
        _errorMessage = 'Recruiter ID is required';
        _isLoading = false;
        notifyListeners();
        return [];
      }

      final response = await _supabaseClient
          .from('job_postings')
          .select()
          .eq('recruiter_id', recruiterId)
          .order('date_posted', ascending: false);

      _jobs = (response as List).map((job) => JobModel.fromJson(job)).toList();

      _isLoading = false;
      notifyListeners();
      return _jobs;
    } catch (e) {
      debugPrint('Error fetching recruiter jobs: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

// Add the closeJob method
  Future<bool> closeJob(int jobId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Closing job ID: $jobId');

      // Update the status to 'Closed'
      await _supabaseClient
          .from('job_postings')
          .update({'status': 'Closed'})
          .eq('job_id', jobId);

      // Update the job in the local list
      final jobIndex = _jobs.indexWhere((job) => job.id == jobId);
      if (jobIndex != -1) {
        final updatedJob = _jobs[jobIndex].copyWith(status: 'Closed');
        _jobs[jobIndex] = updatedJob;
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

  // Get job by ID
  Future<JobModel?> getJobById(int jobId) async {
    try {
      // Check if the job is already in the loaded jobs
      final cachedJob = _jobs.firstWhere(
            (job) => job.id == jobId,
        orElse: () => JobModel(
          jobTitle: '',
          companyName: '',
          jobType: '',
          location: '',
          deadline: DateTime.now(),
          status: '',
          description: '',
          requirements: '',
        ),
      );

      if (cachedJob.id != null) {
        return cachedJob;
      }

      // If not found in cache, fetch from database
      final response = await _supabaseClient
          .from('job_postings')
          .select()
          .eq('job_id', jobId)
          .single();

      return JobModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error getting job by ID: $e');
      return null;
    }
  }

  // Create a new job
  Future<bool> createJob(JobModel job) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final jobData = job.toJson();
      // Remove the ID field when creating a new job
      jobData.remove('job_id');

      await _supabaseClient.from('job_postings').insert(jobData);

      // Refresh the job list
      if (job.recruiterId != null) {
        await fetchRecruiterJobs(job.recruiterId!);
      } else {
        await fetchJobs();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error creating job: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update an existing job
  Future<bool> updateJob(JobModel job) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supabaseClient
          .from('job_postings')
          .update(job.toJson())
          .eq('job_id', job.id);

      // Refresh the job list
      if (job.recruiterId != null) {
        await fetchRecruiterJobs(job.recruiterId!);
      } else {
        await fetchJobs();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating job: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete a job
  Future<bool> deleteJob(int jobId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Deleting job ID: $jobId');
      await _supabaseClient
          .from('job_postings')
          .delete()
          .eq('job_id', jobId);

      // Remove from local lists
      _jobs.removeWhere((job) => job.id == jobId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting job: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Search for jobs
  Future<List<JobModel>> searchJobs(String query) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabaseClient
          .from('job_postings')
          .select()
          .eq('status', 'Open')
          .or('job_title.ilike.%${query}%,job_type.ilike.%${query}%,company_name.ilike.%${query}%,location.ilike.%${query}%,description.ilike.%${query}%')
          .order('date_posted', ascending: false);

      final results = (response as List).map((job) => JobModel.fromJson(job)).toList();

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

  // Apply for a job
  Future<bool> applyForJob(int jobId, String applicantId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    if (_authService == null || _authService!.currentUser == null) {
      _errorMessage = 'You must be logged in to apply for jobs';
      notifyListeners();
      return false;
    }
    final applicantId = _authService!.currentUser!.id;

    try {
      // Check if already applied
      final existingApplication = await _supabaseClient
          .from('applications')
          .select()
          .eq('job_id', jobId)
          .eq('applicant_id', applicantId)
          .maybeSingle();


      if (existingApplication != null) {
        _errorMessage = 'You have already applied for this job';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Create the application
      await _supabaseClient.from('applications').insert({
        'job_id': jobId,
        'applicant_id': applicantId,
        'application_status': 'Pending',
        'date_applied': DateTime.now().toIso8601String(),
      });

      // Refresh applications
      await fetchUserApplications(applicantId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error applying for job: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Add this method to your JobService class
  Future<bool> clearAllApplications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (_authService == null || _authService!.currentUser == null) {
      _errorMessage = 'You must be logged in to manage applications';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final applicantId = _authService!.currentUser!.id;

    try {
      // Delete all applications for this user
      await _supabaseClient
          .from('applications')
          .delete()
          .eq('applicant_id', applicantId);

      // Clear local applications list
      _applications = [];

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error clearing applications: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Fetch applications for a user
  Future<List<ApplicationModel>> fetchUserApplications(String userId) async {
    try {
      final response = await _supabaseClient
          .from('applications')
          .select('''
          application_id,
          job_id,
          applicant_id,
          application_status,
          date_applied,
          recruiter_feedback
        ''')
          .eq('applicant_id', userId)
          .order('date_applied', ascending: false);

      final List<ApplicationModel> applications = [];
      for (var item in response) {
        applications.add(ApplicationModel.fromJson(item));
      }

      _applications = applications;
      notifyListeners();
      return applications;
    } catch (e) {
      debugPrint('Error fetching user applications: $e');
      return [];
    }
  }

  // Update application status
  Future<bool> updateApplicationStatus(int applicationId, String status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Updating application ID: $applicationId to status: $status');

      // Use the correct column name 'application_status'
      await _supabaseClient
          .from('applications')
          .update({'application_status': status})
          .eq('application_id', applicationId);

      debugPrint('Successfully updated application status');

      // Update the application in the local list
      final index = _applications.indexWhere((a) => a.id == applicationId);
      if (index != -1) {
        _applications[index] = _applications[index].copyWith(applicationStatus: status);
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

  // Add these methods to your JobService class

// Get the total number of applications for all jobs by this recruiter
  Future<int> getTotalApplicationsCount(String recruiterId) async {
    try {
      // First get all job IDs for this recruiter
      final jobs = await fetchRecruiterJobs(recruiterId);

      if (jobs.isEmpty) {
        return 0;
      }

      final jobIds = jobs.map((job) => job.id).toList();

      // Count applications for these jobs
      final response = await _supabaseClient
          .from('applications')
          .select('application_id')
          .in_('job_id', jobIds);

      return response.length;
    } catch (e) {
      debugPrint('Error getting application count: $e');
      return 0;
    }
  }

// Get the total number of AI-ranked applications for all jobs by this recruiter
  Future<int> getTotalRankedApplicationsCount(String recruiterId) async {
    try {
      // First get all job IDs for this recruiter
      final jobs = await fetchRecruiterJobs(recruiterId);

      if (jobs.isEmpty) {
        return 0;
      }

      final jobIds = jobs.map((job) => job.id).toList();

      // Count CV rankings for these jobs
      final response = await _supabaseClient
          .from('cv_rankings')
          .select('id')
          .in_('job_id', jobIds);

      return response.length;
    } catch (e) {
      debugPrint('Error getting ranked application count: $e');
      return 0;
    }
  }

// Get application count for a single job
  Future<int> getApplicationCountForJob(int jobId) async {
    try {
      final response = await _supabaseClient
          .from('applications')
          .select('application_id')
          .eq('job_id', jobId);

      return response.length;
    } catch (e) {
      debugPrint('Error getting application count for job $jobId: $e');
      return 0;
    }
  }

// Get only applications for a specific job
  Future<List<ApplicationModel>> getApplicationsForJob(int jobId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _supabaseClient
          .from('applications')
          .select()
          .eq('job_id', jobId)
          .order('date_applied', ascending: false);

      final List<ApplicationModel> applications = [];

      for (final item in response) {
        try {
          applications.add(ApplicationModel(
            id: item['application_id'],
            jobId: item['job_id'],
            applicantId: item['applicant_id'],
            applicationStatus: item['application_status'],
            dateApplied: item['date_applied'] != null
                ? DateTime.parse(item['date_applied'])
                : DateTime.now(),
            recruiterFeedback: item['recruiter_feedback'],
          ));
        } catch (e) {
          debugPrint('Error parsing application: $e');
        }
      }

      _isLoading = false;
      notifyListeners();
      return applications;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

// Get CV ranking information for a job
  Future<List<Map<String, dynamic>>> getCVRankingsForJob(int jobId) async {
    try {
      final response = await _supabaseClient
          .from('cv_rankings')
          .select()
          .eq('job_id', jobId)
          .order('similarity_score', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting CV rankings for job $jobId: $e');
      return [];
    }
  }

  // Delete an application
  Future<bool> deleteApplication(int applicationId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Deleting application ID: $applicationId');
      await _supabaseClient
          .from('applications')
          .delete()
          .eq('application_id', applicationId);

      // Remove from local list
      _applications.removeWhere((app) => app.id == applicationId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting application: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Methods for job dismissal functionality
  Future<void> loadDismissedJobs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissedIds = prefs.getStringList('dismissed_jobs') ?? [];
      _dismissedJobIds = dismissedIds.map((id) => int.parse(id)).toSet();
      _lastDismissedJobsLoadTime = DateTime.now();
      debugPrint('Loaded ${_dismissedJobIds.length} dismissed jobs');
    } catch (e) {
      debugPrint('Error loading dismissed jobs: $e');
    }
  }

  Future<void> dismissJob(int jobId) async {
    try {
      _dismissedJobIds.add(jobId);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          'dismissed_jobs',
          _dismissedJobIds.map((id) => id.toString()).toList()
      );

      notifyListeners();
      debugPrint('Dismissed job with ID: $jobId');
    } catch (e) {
      debugPrint('Error dismissing job: $e');
    }
  }

  Future<void> clearDismissedJobs() async {
    try {
      _dismissedJobIds.clear();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('dismissed_jobs');

      notifyListeners();
      debugPrint('Cleared all dismissed jobs');
    } catch (e) {
      debugPrint('Error clearing dismissed jobs: $e');
    }
  }
  Future<void> _notifyStatusChange({
    required String applicantId,
    required String jobTitle,
    required String status,
  }) async {
    if (_notificationService != null) {
      await _notificationService!.notifyStatusChange(
        applicantId: applicantId,
        jobTitle: jobTitle,
        status: status,
      );
    }
  }
}