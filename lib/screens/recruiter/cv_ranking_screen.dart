import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:tasklink2/models/application_model.dart';
import 'package:tasklink2/models/job_model.dart';
import 'package:tasklink2/models/resume_match_result_model.dart';
import 'package:tasklink2/models/user_model.dart';
import 'package:tasklink2/services/ai_ranking_service.dart';
import 'package:tasklink2/services/job_service.dart';
import 'package:tasklink2/services/notification_service.dart';
import 'package:tasklink2/services/ranking_service.dart';
import 'package:tasklink2/services/resume_match_service.dart';
import 'package:tasklink2/services/resume_service.dart';
import 'package:tasklink2/config/app_config.dart';
import 'package:tasklink2/services/ai_services.dart';
import 'package:tasklink2/services/supabase_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/supabase_service.dart';

class CVRankingScreen extends StatefulWidget {
  final JobModel job;

  const CVRankingScreen({Key? key, required this.job}) : super(key: key);

  @override
  _CVRankingScreenState createState() => _CVRankingScreenState();
}

class _CVRankingScreenState extends State<CVRankingScreen> with SingleTickerProviderStateMixin {
  final RankingService _rankingService = RankingService(
    supabaseClient: AppConfig().supabaseClient,
    aiService: AIService(baseUrl: AppConfig.backendUrl),
  );

  // Services
  final ResumeMatchService _resumeMatchService = ResumeMatchService();
  final ResumeService _resumeService = ResumeService(
    supabaseClient: AppConfig().supabaseClient,
    aiService: AIService(baseUrl: AppConfig.backendUrl),
  );
  late NotificationService _notificationService;

  late TabController _tabController;

  // State variables
  bool _isLoading = false;
  List<Map<String, dynamic>> _rankedApplications = [];
  String? _errorMessage;
  ResumeMatchResultModel? _personalMatchResult;
  bool _isMatchingPersonalResume = false;
  String? _personalResumeText;
  String? _currentUserId;
  var score_value;

  // New state variables for recruiter feedback
  final Map<String, TextEditingController> _feedbackControllers = {};
  final Map<String, bool> _isSendingFeedback = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentUserId = AppConfig().supabaseClient.auth.currentUser?.id;
    _fetchRankedApplications();
    _loadExistingMatchResult();

    // Initialize notification service
    _notificationService = Provider.of<NotificationService>(context, listen: false);

  }

  @override
  void dispose() {
    _tabController.dispose();
    // Dispose all feedback controllers
    for (var controller in _feedbackControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _getApplicantName(Map<String, dynamic> rankedApplication) {
    try {
      // First check if it's directly in the rankedApplication
      if (rankedApplication['applicant_name'] != null) {
        return rankedApplication['applicant_name'];
      }

      // Try to get from the application object
      final application = rankedApplication['application'];
      if (application != null && application is Map) {
        // Check for direct applicant_name in application
        if (application['applicant_name'] != null) {
          return application['applicant_name'];
        }

        // Check for application ID
        if (application['application_id'] != null) {
          return 'Application #${application['application_id']}';
        }

        // Check for applicant object
        if (application['applicant'] != null) {
          final applicant = application['applicant'];
          if (applicant is Map) {
            if (applicant['name'] != null) return applicant['name'];
            if (applicant['email'] != null) return applicant['email'];
          }
        }

        // Try applicant_id
        if (application['applicant_id'] != null) {
          final id = application['applicant_id'].toString();
          // Use dart syntax for min
          return 'Applicant ${id.substring(0, id.length > 8 ? 8 : id.length)}';
        }
      }

      // Default fallback
      return 'Unknown Applicant';
    } catch (e) {
      debugPrint('Error getting applicant name: $e');
      return 'Unknown Applicant';
    }
  }

  // Get applicant ID from ranked application
  String? _getApplicantId(Map<String, dynamic> rankedApplication) {
    try {
      final application = rankedApplication['application'];
      if (application != null && application is Map) {
        return application['applicant_id']?.toString();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting applicant ID: $e');
      return null;
    }
  }

  // Get application ID from ranked application
  int? _getApplicationId(Map<String, dynamic> rankedApplication) {
    try {
      final application = rankedApplication['application'];
      if (application != null && application is Map) {
        return application['application_id'];
      }
      return null;
    } catch (e) {
      debugPrint('Error getting application ID: $e');
      return null;
    }
  }

  // Load existing match result if available
  Future<void> _loadExistingMatchResult() async {
    if (_currentUserId == null) return;

    setState(() {
      _isMatchingPersonalResume = true;
    });

    try {
      // Check if we already have a stored match result
      final matchResult = await _resumeMatchService.getMatchResult(
        jobId: widget.job.id!.toString(),
        applicantId: _currentUserId!,
      );

      if (matchResult != null) {
        setState(() {
          _personalMatchResult = matchResult;
          _isMatchingPersonalResume = false;
        });
      } else {
        // If no existing result, fetch resume and perform match
        await _fetchPersonalResumeAndMatch();
      }
    } catch (e) {
      debugPrint("Error loading existing match result: $e");
      setState(() {
        _isMatchingPersonalResume = false;
        _errorMessage = "Error loading match result: $e";
      });
    }
  }

  Future<void> _fetchPersonalResumeAndMatch() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        setState(() {
          _isMatchingPersonalResume = false;
          _errorMessage = "You need to be logged in to match your resume.";
        });
        return;
      }

      final resume = await _resumeService.getCurrentUserResume();
      if (resume != null && resume['text'] != null) {
        setState(() {
          _personalResumeText = resume['text'];
        });

        // Perform match and store result
        final matchResult = await _resumeMatchService.matchAndStoreResult(
          jobId: widget.job.id!.toString(),
          applicantId: userId,
          resumeText: resume['text'],
          jobDescription: widget.job.description ?? "",
        );

        setState(() {
          _personalMatchResult = matchResult;
          _isMatchingPersonalResume = false;
        });
      } else {
        setState(() {
          _isMatchingPersonalResume = false;
          _errorMessage = "Rank Available Applicants.";
        });
      }
    } catch (e) {
      debugPrint("Error fetching personal resume: $e");
      setState(() {
        _isMatchingPersonalResume = false;
        _errorMessage = "Error: $e";
      });
    }
  }

  List<List<String>> classifySkills(List<WordMatch> wordMatches) {
    final matchedSkills = <String>[];
    final missedSkills = <String>[];

    for (var match in wordMatches) {
      final score = match.score;
      final skill = match.resumeWord;

      if (score >= 0.6) {
        matchedSkills.add(skill);
      } else {
        missedSkills.add(skill);
      }
    }

    return [matchedSkills, missedSkills];
  }

  Future<void> _fetchRankedApplications() async {
    if (_currentUserId == null || !mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // First check if we have match results in the database
      final matchResults = await _resumeMatchService.getMatchResultsForJob(
          widget.job.id!.toString()  // Ensure string type
      );

      print("ID ${widget.job.id!.toString()}");

      final similarityService = SimilarityService(
        baseUrl: 'http://192.168.1.7:8000',
      );

      if (!mounted) return;  // Check if widget is still mounted

      if (matchResults.isNotEmpty) {
        // We have match results, convert them to the format expected by the UI
        final List<Map<String, dynamic>> applicationsList = [];

        for (final result in matchResults) {
          try {
            print("Applicant ${result.applicantId}");
            final appData = await AppConfig().supabaseClient
                .from('applications')
                .select('*')
                .eq('applicant_id', result.applicantId)
                .eq('job_id', widget.job.id)
                .single();

            final resume = await _resumeService.getUserResume(result.applicantId);
            // final jobDescription = "Testing";
            final jobDescription = await AppConfig().supabaseClient.from("job_postings").select("description").eq("job_id", widget.job.id).limit(1).single();
            // print("jd: $jobDescription");
            score_value = await similarityService.checkFileSimilarity(resume: resume!["text"], jobDescription: jobDescription["description"], threshold: 0.7);

            // print("URL: $resumeURL -> ${result.applicantId}");

            var skills = classifySkills(score_value.wordMatches);

            // print("Skills: $skills");

            applicationsList.add({
              'application': appData,
              'score': score_value.similarityScore,
              'matching_skills': skills[0],
              'missing_skills': skills[1],
              'decision': score_value.decision,
              // 'improvement_suggestions': result.improvementSuggestions,
            });
          } catch (e) {
            debugPrint('Error loading application data for ${result.applicantId}: $e');
            // Continue with next result
          }
        }

        // Sort by score in descending order
        applicationsList.sort((a, b) => (b['score'] as num).compareTo(a['score'] as num));

        print("Applist: $applicationsList");

        if (!mounted) return;

        setState(() {
          _rankedApplications = applicationsList;
          _isLoading = false;
        });
      } else {
        // No stored results, use traditional ranking method
        if (!mounted) return;
        await _performRanking();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching ranking results: $e';
      });
    }
  }

// Rename to avoid duplicate method name
  Future<void> _performRanking() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rankedApplications = await _rankingService.rankApplications(
        widget.job.id!.toString(),  // Ensure string type
        widget.job.description,
      );

      if (!mounted) return;

      setState(() {
        _rankedApplications = rankedApplications;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Error ranking applications: $e';
      });
    }
  }
  // New method to handle application status updates
  Future<void> _updateApplicationStatus(int applicationId, String status) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final jobService = Provider.of<JobService>(context, listen: false);
      final success = await jobService.updateApplicationStatus(applicationId, status);

      if (success) {
        // Get applicant ID to send notification
        final applicationIndex = _rankedApplications.indexWhere(
                (app) => _getApplicationId(app) == applicationId
        );

        if (applicationIndex >= 0) {
          final applicantId = _getApplicantId(_rankedApplications[applicationIndex]);
          if (applicantId != null) {
            // Send notification to applicant
            await _notificationService.sendNotification(
              userId: applicantId,
              title: "Application Status Update",
              body: "Your application for ${widget.job.jobTitle} has been marked as $status",
              type: "application_update",
              data: {
                "job_id": widget.job.id.toString(),
                "status": status,
              },
            );
          }
        }

        // Refresh the application list
        await _fetchRankedApplications();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application status updated to $status'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update application status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // New method to send feedback to job seeker
  Future<void> _sendFeedbackToApplicant(String applicantId, int applicationId) async {
    if (!_feedbackControllers.containsKey(applicantId) ||
        _feedbackControllers[applicantId]!.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter feedback before sending'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSendingFeedback[applicantId] = true;
    });

    try {
      // Update application with recruiter feedback
      final feedback = _feedbackControllers[applicantId]!.text.trim();

      // Save feedback to database
      await AppConfig().supabaseClient
          .from('applications')
          .update({'recruiter_feedback': feedback})
          .eq('application_id', applicationId);

      // Send notification to applicant
      await _notificationService.sendNotification(
        userId: applicantId,
        title: "Recruiter Feedback",
        body: "You've received feedback on your application for ${widget.job.jobTitle}",
        type: "recruiter_feedback",
        data: {
          "job_id": widget.job.id.toString(),
          "application_id": applicationId.toString(),
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending feedback: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSendingFeedback[applicantId] = false;
      });
    }
  }
  // Add this method to your ResumeService class

  /// Get a user's resume by their ID
  Future<Map<String, dynamic>?> getUserResume(String userId) async {
    try {
      // First try to get the resume file from storage
      final response = await AppConfig().supabaseClient
          .from('resumes')
          .select('file_url, text, created_at, resume_id')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        debugPrint('No resume found for user $userId');
        return null;
      }

      return response;
    } catch (e) {
      debugPrint('Error fetching resume for user $userId: $e');
      return null;
    }
  }
  // Method to view or download a resume
  Future<void> downloadAndSaveCV(BuildContext context, String applicantId) async {
    final supabaseService = SupabaseService();

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Accessing CV'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Locating CV file...'),
          ],
        ),
      ),
    );

    try {
      // Get the jobseeker profile to find the CV URL
      final profileData = await supabaseService.getJobseekerProfileData(applicantId);

      // Close the loading dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Check if profile and CV exists
      if (profileData == null || profileData['cv'] == null || profileData['cv'].toString().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No CV found for this applicant'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final cvUrl = profileData['cv'].toString();
      debugPrint('Found CV URL: $cvUrl');

      // Extract filename from the URL
      String filename = cvUrl.split('/').last;
      if (filename.isEmpty || !filename.contains('.')) {
        // If filename is invalid or has no extension, use a default name with timestamp
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        filename = 'applicant_cv_$timestamp.pdf';
      }

      // Show download progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          title: Text('Downloading'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Downloading CV file...'),
            ],
          ),
        ),
      );

      try {
        // Get the response from the URL
        final response = await http.get(Uri.parse(cvUrl));

        if (response.statusCode != 200) {
          throw Exception('Failed to download file: HTTP ${response.statusCode}');
        }

        // Determine where to save the file
        final filePath = await _getSaveLocation(filename);

        if (filePath == null) {
          // User canceled or directory selection failed
          // Close download dialog
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Download canceled'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        // Write to the file
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Close download dialog
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        // Show success dialog with file path
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Download Complete'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CV has been downloaded successfully.'),
                const SizedBox(height: 8),
                const Text('File saved to:'),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    filePath,
                    style: const TextStyle(fontWeight: FontWeight.bold, color:Colors.black),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              // Option to share the file
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Share.shareXFiles([XFile(filePath)], text: 'Applicant CV: $filename');
                },
                child: const Text('Share'),
              ),
            ],
          ),
        );
      } catch (e) {
        // Close download dialog if open
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        debugPrint('Error downloading CV: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading CV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      debugPrint('Error fetching profile or CV: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accessing CV: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// Helper method to get the save location
  Future<String?> _getSaveLocation(String filename) async {
    try {
      // For Android and iOS, use the downloads directory
      final directory = await _getDownloadsDirectory();

      if (directory != null) {
        // Create a unique filename if one already exists
        final baseFilename = filename.contains('.')
            ? filename.substring(0, filename.lastIndexOf('.'))
            : filename;
        final extension = filename.contains('.')
            ? filename.substring(filename.lastIndexOf('.'))
            : '.pdf';

        String uniqueFilename = filename;
        int counter = 1;

        while (await File('${directory.path}/$uniqueFilename').exists()) {
          uniqueFilename = '${baseFilename}_$counter$extension';
          counter++;
        }

        return '${directory.path}/$uniqueFilename';
      }
      return null;
    } catch (e) {
      debugPrint('Error getting save location: $e');
      return null;
    }
  }

// Helper to get downloads directory based on platform
  Future<Directory?> _getDownloadsDirectory() async {
    try {
      if (Platform.isAndroid) {
        // For Android, use the Downloads directory
        final directory = Directory('/storage/emulated/0/Download');
        if (await directory.exists()) {
          return directory;
        }

        // Fallback to external storage directory
        final externalDir = await getExternalStorageDirectory();
        return externalDir;
      } else if (Platform.isIOS) {
        // For iOS, use the Documents directory
        final directory = await getApplicationDocumentsDirectory();
        return directory;
      } else {
        // For other platforms, use temp directory
        final directory = await getTemporaryDirectory();
        return directory;
      }
    } catch (e) {
      debugPrint('Error getting downloads directory: $e');
      // Fallback to temp directory
      return await getTemporaryDirectory();
    }
  }

  // Helper to launch URL
  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open URL: $url'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if user is recruiter (posted the job) or applicant
    final isRecruiter = widget.job.recruiterId == _currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(isRecruiter ? 'Applicant Ranking' : 'Job Match Analysis'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: isRecruiter ? 'Applications' : 'All Applications'),
            Tab(text: isRecruiter ? 'Analytics' : 'My Match'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRankingTab(),
          isRecruiter ? _buildRecruiterAnalyticsTab() : _buildPersonalMatchTab(),
        ],
      ),
    );
  }

  Widget _buildRankingTab() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading ranked applications...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user, size: 48, color: Colors.green),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _performRanking,
              child: const Text('Rank Applicants'),
            ),
          ],
        ),
      );
    }

    if (_rankedApplications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No applications to rank for this job.'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rankedApplications.length,
      itemBuilder: (context, index) {
        final rankedApp = _rankedApplications[index];
        final application = rankedApp['application'];
        final score = rankedApp['score'];
        final matchingSkills = rankedApp['matching_skills'];
        final missingSkills = rankedApp['missing_skills'];
        final decision = rankedApp['decision'] ?? (score > 0.75 ? 'Match' : 'No Match');
        final improvement = rankedApp['improvement_suggestions'];
        final applicantId = _getApplicantId(rankedApp);
        final applicationId = _getApplicationId(rankedApp);

        // Get current application status
        final String applicationStatus = application['application_status'] ?? 'Pending';

        // Create feedback controller if needed
        if (applicantId != null && !_feedbackControllers.containsKey(applicantId)) {
          _feedbackControllers[applicantId] = TextEditingController(
              text: rankedApp['recruiter_feedback'] ?? ''
          );
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Applicant name and score
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _getApplicantName(rankedApp),
                        style: Theme.of(context).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getScoreColor(score),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        score != null
                            ? 'Score: ${(score * 100).toStringAsFixed(1)}%'
                            : 'No Score',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Decision chip and current status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: decision == 'Match' ? Colors.green.shade100 : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        decision,
                        style: TextStyle(
                          color: decision == 'Match' ? Colors.green.shade800 : Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Application status chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(applicationStatus).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Status: $applicationStatus',
                        style: TextStyle(
                          color: _getStatusColor(applicationStatus),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Matching Skills
                if (matchingSkills != null && matchingSkills.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Matching Skills:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(
                          matchingSkills.length > 5 ? 5 : matchingSkills.length,
                              (i) => Chip(
                            label: Text(matchingSkills[i]),
                            backgroundColor: Colors.green.shade100,
                          ),
                        ),
                      ),
                    ],
                  ),

                // Missing Skills
                if (missingSkills != null && missingSkills.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      const Text(
                        'Missing Skills:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(
                          missingSkills.length > 5 ? 5 : missingSkills.length,
                              (i) => Chip(
                            label: Text(missingSkills[i]),
                            backgroundColor: Colors.red.shade100,
                          ),
                        ),
                      ),
                    ],
                  ),

                // Show improvement suggestions for recruiters
                if (widget.job.recruiterId == _currentUserId && improvement != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      const Text(
                        'Notes:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        improvement,
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),

                // For recruiters only - Add feedback for applicant
                if (widget.job.recruiterId == _currentUserId && applicantId != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        'Feedback for Applicant:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _feedbackControllers[applicantId],
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Enter feedback or comments for this applicant...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: _isSendingFeedback[applicantId] == true
                              ? null
                              : () => _sendFeedbackToApplicant(applicantId, applicationId!),
                          icon: _isSendingFeedback[applicantId] == true
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Icon(Icons.send),
                          label: const Text('Send Feedback'),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // For recruiters - Download CV
                    if (widget.job.recruiterId == _currentUserId && applicantId != null)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Download CV'),
                        onPressed: () => downloadAndSaveCV(context, applicantId),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: BorderSide(color: Theme.of(context).colorScheme.primary),
                        ),
                      ),

                    const SizedBox(width: 8),

                    // For recruiters - Status Update Button with Popup
                    if (widget.job.recruiterId == _currentUserId && applicationId != null)
                      PopupMenuButton<String>(
                        onSelected: (status) {
                          _updateApplicationStatus(applicationId, status);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'Pending',
                            child: Text('Mark as Pending'),
                          ),
                          const PopupMenuItem(
                            value: 'Selected',
                            child: Text('Mark as Selected'),
                          ),
                          const PopupMenuItem(
                            value: 'Rejected',
                            child: Text('Mark as Rejected'),
                          ),
                        ],
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.update, size: 16,),
                          label: const Text('Update Status'),
                          onPressed: null, // handled by PopupMenuButton
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            side: BorderSide(color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ),

                    const SizedBox(width: 8),

                    // For job seekers - View Job Details
                    if (widget.job.recruiterId != _currentUserId)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('View Job Details'),
                        onPressed: () {
                          // Navigate to job details
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: BorderSide(color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                  ],
                )


              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPersonalMatchTab() {
    // Implementation same as before
    return const Center(child: Text("My Match Tab"));
  }

  Widget _buildRecruiterAnalyticsTab() {
    // Implementation same as before
    return const Center(child: Text("Analytics Tab"));
  }

  Widget _buildScoreIndicator(double score) {
    return Row(
      children: [
        Container(
          width: 120,
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: Colors.grey.shade200,
          ),
          child: Row(
            children: [
              // Green zone (80-100%)
              Container(
                width: 120 * 0.2, // 20% of total width
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(6),
                    bottomLeft: Radius.circular(6),
                  ),
                  color: Colors.green.shade200,
                ),
              ),
              // Yellow zone (65-80%)
              Container(
                width: 120 * 0.15, // 15% of total width
                color: Colors.lightGreen.shade200,
              ),
              // Orange zone (50-65%)
              Container(
                width: 120 * 0.15, // 15% of total width
                color: Colors.orange.shade200,
              ),
              // Red zone (0-50%)
              Container(
                width: 120 * 0.5, // 50% of total width
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                  color: Colors.red.shade200,
                ),
              ),
            ],
          ),
        ),
        // Indicator of current score
        Container(
          margin: EdgeInsets.only(top: -10, left: score * 120 - 8),
          child: Icon(
            Icons.arrow_drop_down,
            color: _getScoreColor(score),
            size: 24,
          ),
        ),
      ],
    );
  }


  Widget _buildDecisionLabel(String decision) {
    Color bgColor;
    Color textColor;

    switch (decision) {
      case "Strong Match":
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case "Good Match":
        bgColor = Colors.lightGreen.shade100;
        textColor = Colors.green.shade700;
        break;
      case "Potential Match":
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      default: // "No Match"
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        decision,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }


  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Selected':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getScoreColor(double? score) {
    if (score == null) return Colors.grey;
    if (score >= 0.80) return Colors.green.shade700;
    if (score >= 0.65) return Colors.green.shade500;
    if (score >= 0.50) return Colors.orange.shade500;
    return Colors.red.shade500;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}