import 'package:flutter/foundation.dart';
import 'package:tasklink2/services/supabase_service.dart';

class AnalyticsService extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  // Get job performance analytics for a recruiter
  Future<Map<String, dynamic>> getJobAnalytics(String recruiterId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get jobs data
      final jobsResponse = await _supabaseService.supabase
          .from('job_postings')
          .select('job_id, job_title, date_posted, deadline, status')
          .eq('recruiter_id', recruiterId)
          .order('date_posted', ascending: false);

      // Get applications data - use 'filter' instead of 'in'
      List<int> jobIds = [];
      if (jobsResponse != null && jobsResponse is List) {
        jobIds = jobsResponse
            .map<int>((job) => job['job_id'] as int)
            .toList();
      }

      List<dynamic> applicationsResponse = [];
      if (jobIds.isNotEmpty) {
        applicationsResponse = await _supabaseService.supabase
            .from('applications')
            .select('application_id, job_id, application_status')
            .filter('job_id', 'in', jobIds);
      }

      // Calculate metrics
      final metrics = _calculateMetrics(jobsResponse ?? [], applicationsResponse ?? []);

      _isLoading = false;
      notifyListeners();

      return metrics;
    } catch (e) {
      print('Error getting job analytics: $e');
      _isLoading = false;
      notifyListeners();

      return {
        'error': 'Failed to load analytics',
      };
    }
  }

  // Get application conversion analytics
  Future<Map<String, dynamic>> getApplicationConversionAnalytics(String recruiterId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get jobs data
      final jobsResponse = await _supabaseService.supabase
          .from('job_postings')
          .select('job_id')
          .eq('recruiter_id', recruiterId);

      List<int> jobIds = [];
      if (jobsResponse != null && jobsResponse is List) {
        jobIds = jobsResponse
            .map<int>((job) => job['job_id'] as int)
            .toList();
      }

      // Get applications data
      List<dynamic> applicationsResponse = [];
      if (jobIds.isNotEmpty) {
        applicationsResponse = await _supabaseService.supabase
            .from('applications')
            .select('application_id, job_id, application_status')
            .filter('job_id', 'in', jobIds);
      }

      // Calculate conversion rates
      final conversions = _calculateConversionRates(applicationsResponse ?? []);

      _isLoading = false;
      notifyListeners();

      return conversions;
    } catch (e) {
      print('Error getting application conversion analytics: $e');
      _isLoading = false;
      notifyListeners();

      return {
        'error': 'Failed to load conversion analytics',
      };
    }
  }

  // Get CV ranking effectiveness analytics
  Future<Map<String, dynamic>> getRankingAnalytics(String recruiterId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get jobs data
      final jobsResponse = await _supabaseService.supabase
          .from('job_postings')
          .select('job_id')
          .eq('recruiter_id', recruiterId);

      List<int> jobIds = [];
      if (jobsResponse != null && jobsResponse is List) {
        jobIds = jobsResponse
            .map<int>((job) => job['job_id'] as int)
            .toList();
      }

      // Get applications with rankings
      List<dynamic> applicationsResponse = [];
      if (jobIds.isNotEmpty) {
        applicationsResponse = await _supabaseService.supabase
            .from('applications')
            .select('application_id, job_id, application_status')
            .filter('job_id', 'in', jobIds);
      }

      // Get rankings
      List<dynamic> rankingsResponse = [];
      List<int> applicationIds = [];
      if (applicationsResponse != null && applicationsResponse is List) {
        applicationIds = applicationsResponse
            .map<int>((app) => app['application_id'] as int)
            .toList();
      }

      if (applicationIds.isNotEmpty) {
        rankingsResponse = await _supabaseService.supabase
            .from('cv_rankings')
            .select('application_id, rank_score, recommendation_status')
            .filter('application_id', 'in', applicationIds);
      }

      // Calculate ranking effectiveness
      final rankingMetrics = _calculateRankingEffectiveness(
          applicationsResponse ?? [],
          rankingsResponse ?? []
      );

      _isLoading = false;
      notifyListeners();

      return rankingMetrics;
    } catch (e) {
      print('Error getting ranking analytics: $e');
      _isLoading = false;
      notifyListeners();

      return {
        'error': 'Failed to load ranking analytics',
      };
    }
  }

  // Calculate job and application metrics
  Map<String, dynamic> _calculateMetrics(
      List<dynamic> jobs,
      List<dynamic> applications
      ) {
    // Job metrics
    final int totalJobs = jobs.length;
    final int activeJobs = jobs.where((job) => job['status'] == 'Open').length;
    final int closedJobs = jobs.where((job) => job['status'] == 'Closed').length;

    // Time-based metrics
    final now = DateTime.now();
    final lastMonthJobs = jobs.where((job) {
      final datePosted = DateTime.parse(job['date_posted']);
      return now.difference(datePosted).inDays <= 30;
    }).length;

    // Application metrics
    final int totalApplications = applications.length;
    final int pendingApplications = applications.where((app) =>
    app['application_status'] == 'Pending').length;
    final int selectedApplications = applications.where((app) =>
    app['application_status'] == 'Selected').length;
    final int rejectedApplications = applications.where((app) =>
    app['application_status'] == 'Rejected').length;

    // Applications per job
    final applicationsPerJob = totalJobs > 0
        ? totalApplications / totalJobs
        : 0;

    // Selection rate
    final selectionRate = totalApplications > 0
        ? (selectedApplications / totalApplications) * 100
        : 0;

    // Compile all metrics
    return {
      'jobMetrics': {
        'totalJobs': totalJobs,
        'activeJobs': activeJobs,
        'closedJobs': closedJobs,
        'lastMonthJobs': lastMonthJobs,
      },
      'applicationMetrics': {
        'totalApplications': totalApplications,
        'pendingApplications': pendingApplications,
        'selectedApplications': selectedApplications,
        'rejectedApplications': rejectedApplications,
        'applicationsPerJob': applicationsPerJob.toStringAsFixed(1),
        'selectionRate': selectionRate.toStringAsFixed(1) + '%',
      },
      'timeMetrics': {
        'avgTimeToFill': _calculateAverageTimeToFill(jobs, applications),
      },
    };
  }

  // Calculate conversion rates for the application funnel
  Map<String, dynamic> _calculateConversionRates(List<dynamic> applications) {
    final int totalApplications = applications.length;
    final int pendingApplications = applications.where((app) =>
    app['application_status'] == 'Pending').length;
    final int selectedApplications = applications.where((app) =>
    app['application_status'] == 'Selected').length;
    final int rejectedApplications = applications.where((app) =>
    app['application_status'] == 'Rejected').length;

    // Calculate funnel conversion rates
    final double pendingToSelectedRate = pendingApplications > 0
        ? (selectedApplications / (pendingApplications + selectedApplications + rejectedApplications)) * 100
        : 0;

    final double overallConversionRate = totalApplications > 0
        ? (selectedApplications / totalApplications) * 100
        : 0;

    // Group applications by job to calculate per-job conversion rates
    final Map<int, Map<String, int>> jobApplications = {};

    for (final app in applications) {
      final jobId = app['job_id'];
      final status = app['application_status'];

      if (!jobApplications.containsKey(jobId)) {
        jobApplications[jobId] = {
          'total': 0,
          'pending': 0,
          'selected': 0,
          'rejected': 0,
        };
      }

      jobApplications[jobId]!['total'] = jobApplications[jobId]!['total']! + 1;

      if (status == 'Pending') {
        jobApplications[jobId]!['pending'] = jobApplications[jobId]!['pending']! + 1;
      } else if (status == 'Selected') {
        jobApplications[jobId]!['selected'] = jobApplications[jobId]!['selected']! + 1;
      } else if (status == 'Rejected') {
        jobApplications[jobId]!['rejected'] = jobApplications[jobId]!['rejected']! + 1;
      }
    }

    // Calculate high and low performing jobs
    final List<Map<String, dynamic>> jobConversionRates = [];

    jobApplications.forEach((jobId, counts) {
      if (counts['total']! >= 5) { // Only consider jobs with at least 5 applications
        final conversionRate = counts['total']! > 0
            ? (counts['selected']! / counts['total']!) * 100
            : 0;

        jobConversionRates.add({
          'jobId': jobId,
          'conversionRate': conversionRate,
          'applicationsCount': counts['total'],
          'selectedCount': counts['selected'],
        });
      }
    });

    // Sort by conversion rate
    jobConversionRates.sort((a, b) =>
        (b['conversionRate'] as double).compareTo(a['conversionRate'] as double));

    // Get top and bottom performers
    final highPerformingJobs = jobConversionRates.isNotEmpty
        ? jobConversionRates.sublist(0, jobConversionRates.length > 3 ? 3 : jobConversionRates.length)
        : [];

    final lowPerformingJobs = jobConversionRates.length > 3
        ? jobConversionRates.sublist(jobConversionRates.length - 3, jobConversionRates.length).reversed.toList()
        : [];

    return {
      'overallConversion': {
        'totalApplications': totalApplications,
        'selectedApplications': selectedApplications,
        'conversionRate': overallConversionRate.toStringAsFixed(1) + '%',
        'pendingToSelectedRate': pendingToSelectedRate.toStringAsFixed(1) + '%',
      },
      'highPerformingJobs': highPerformingJobs,
      'lowPerformingJobs': lowPerformingJobs,
    };
  }

  // Calculate ranking algorithm effectiveness
  Map<String, dynamic> _calculateRankingEffectiveness(
      List<dynamic> applications,
      List<dynamic> rankings
      ) {
    if (rankings.isEmpty) {
      return {
        'rankingAvailable': false,
        'message': 'No ranking data available yet',
      };
    }

    // Create a map of application_id to application status
    final Map<int, String> applicationStatuses = {};
    for (final app in applications) {
      applicationStatuses[app['application_id']] = app['application_status'];
    }

    // Track matches between AI recommendations and actual outcomes
    int correctRecommendations = 0;
    int totalRanked = 0;

    // High score selections
    int highScoreTotal = 0;
    int highScoreSelected = 0;

    // Medium score selections
    int mediumScoreTotal = 0;
    int mediumScoreSelected = 0;

    // Low score selections
    int lowScoreTotal = 0;
    int lowScoreSelected = 0;

    for (final ranking in rankings) {
      final appId = ranking['application_id'];
      final score = ranking['rank_score'];
      final recommendation = ranking['recommendation_status'];
      final actualStatus = applicationStatuses[appId];

      // Only count applications that have been processed (not pending)
      if (actualStatus != null && actualStatus != 'Pending') {
        totalRanked++;

        // Check if recommendation matches actual outcome
        if ((recommendation == 'Highly Recommended' && actualStatus == 'Selected') ||
            (recommendation == 'Consider' && actualStatus == 'Rejected')) {
          correctRecommendations++;
        }

        // Track selection rates by score ranges
        if (score >= 0.8) {
          highScoreTotal++;
          if (actualStatus == 'Selected') highScoreSelected++;
        } else if (score >= 0.6) {
          mediumScoreTotal++;
          if (actualStatus == 'Selected') mediumScoreSelected++;
        } else {
          lowScoreTotal++;
          if (actualStatus == 'Selected') lowScoreSelected++;
        }
      }
    }

    // Calculate effectiveness percentages
    final double accuracyRate = totalRanked > 0
        ? (correctRecommendations / totalRanked) * 100
        : 0;

    final double highScoreSelectionRate = highScoreTotal > 0
        ? (highScoreSelected / highScoreTotal) * 100
        : 0;

    final double mediumScoreSelectionRate = mediumScoreTotal > 0
        ? (mediumScoreSelected / mediumScoreTotal) * 100
        : 0;

    final double lowScoreSelectionRate = lowScoreTotal > 0
        ? (lowScoreSelected / lowScoreTotal) * 100
        : 0;

    return {
      'rankingAvailable': true,
      'totalRankedApplications': totalRanked,
      'accuracyRate': accuracyRate.toStringAsFixed(1) + '%',
      'selectionRatesByScore': {
        'highScore': {
          'total': highScoreTotal,
          'selected': highScoreSelected,
          'rate': highScoreSelectionRate.toStringAsFixed(1) + '%',
        },
        'mediumScore': {
          'total': mediumScoreTotal,
          'selected': mediumScoreSelected,
          'rate': mediumScoreSelectionRate.toStringAsFixed(1) + '%',
        },
        'lowScore': {
          'total': lowScoreTotal,
          'selected': lowScoreSelected,
          'rate': lowScoreSelectionRate.toStringAsFixed(1) + '%',
        },
      },
    };
  }

  // Calculate average time to fill a position
  String _calculateAverageTimeToFill(List<dynamic> jobs, List<dynamic> applications) {
    // Group selected applications by job
    final Map<int, DateTime> firstSelectionByJob = {};

    for (final app in applications) {
      if (app['application_status'] == 'Selected') {
        final jobId = app['job_id'];
        final selectionDate = DateTime.now(); // In a real scenario, we'd store the selection date

        if (!firstSelectionByJob.containsKey(jobId) ||
            selectionDate.isBefore(firstSelectionByJob[jobId]!)) {
          firstSelectionByJob[jobId] = selectionDate;
        }
      }
    }

    // Calculate time to fill for each job
    final List<int> daysToFill = [];

    for (final job in jobs) {
      final jobId = job['job_id'];

      if (firstSelectionByJob.containsKey(jobId)) {
        final postDate = DateTime.parse(job['date_posted']);
        final selectionDate = firstSelectionByJob[jobId]!;

        final daysDifference = selectionDate.difference(postDate).inDays;
        daysToFill.add(daysDifference);
      }
    }

    // Calculate average
    if (daysToFill.isEmpty) {
      return 'N/A';
    }

    final avgDays = daysToFill.reduce((a, b) => a + b) / daysToFill.length;
    return '${avgDays.toStringAsFixed(1)} days';
  }
}