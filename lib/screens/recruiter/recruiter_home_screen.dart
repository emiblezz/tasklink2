import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasklink2/models/application_model.dart';
import 'package:tasklink2/models/job_model.dart';
import 'package:tasklink2/models/user_model.dart';
import 'package:tasklink2/models/jobseeker_profile_model.dart';
import 'package:tasklink2/screens/auth/login_screen.dart';
import 'package:tasklink2/screens/job_detail_screen.dart';
import 'package:tasklink2/screens/recruiter/create_job_screen.dart';
import 'package:tasklink2/screens/recruiter/cv_ranking_screen.dart';
import 'package:tasklink2/screens/recruiter/recruiter_jobs_screen.dart';
import 'package:tasklink2/services/auth_service.dart';
import 'package:tasklink2/services/job_service.dart';
import 'package:tasklink2/services/supabase_service.dart';
import 'package:tasklink2/services/resume_service.dart';
import 'package:tasklink2/config/app_config.dart';
import 'package:tasklink2/services/ai_services.dart';
import 'package:tasklink2/widgets/job_card.dart';
import 'package:tasklink2/widgets/notification_badge.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../help_desk_screen.dart';
import '../settings_screen.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class RecruiterHomeScreen extends StatefulWidget {
  const RecruiterHomeScreen({super.key});

  @override
  State<RecruiterHomeScreen> createState() => _RecruiterHomeScreenState();
}

class _RecruiterHomeScreenState extends State<RecruiterHomeScreen> {
  int _selectedIndex = 0;
  final SupabaseService _supabaseService = SupabaseService();
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }
  void _navigateToCVRanking(JobModel job) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CVRankingScreen(job: job),
      ),
    ).then((_) => setState(() {})); // Refresh after returning
  }

  Future<void> _loadInitialData() async {
    final jobService = Provider.of<JobService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    if (authService.currentUser != null) {
      await jobService.fetchRecruiterJobs(authService.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pages for bottom navigation
    final List<Widget> _pages = [
      const _DashboardTab(),
      const _JobPostingsTab(),
      const _CandidatesTab(),
      const _ProfileTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskLink Recruiter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.work_outline),
            tooltip: 'Manage Job Postings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RecruiterJobsScreen(),
                ),
              ).then((_) {
                // Refresh data when returning from jobs screen
                _loadInitialData();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(isRecruiter: true),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpDeskScreen(isRecruiter: true),
                ),
              );
            },
          ),
          NotificationBadge(
            child: IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              tooltip: 'Notifications',
              onPressed: null, // The badge handles the tap
            ),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateJobScreen(),
            ),
          ).then((_) {
            // Refresh job listings when returning from create job screen
            final jobService = Provider.of<JobService>(context, listen: false);
            final authService = Provider.of<AuthService>(context, listen: false);

            if (authService.currentUser != null) {
              jobService.fetchRecruiterJobs(authService.currentUser!.id);
            }
          });
        },
        child: const Icon(Icons.add),
      )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Candidates',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Dashboard Tab
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final jobService = Provider.of<JobService>(context);
    final jobs = jobService.jobs;

    // Calculate dashboard stats
    final activeJobs = jobs.where((job) => job.status == 'Open').length;
    final closedJobs = jobs.where((job) => job.status == 'Closed').length;
    final totalApplications = 0; // This would require additional API call
    final rankedApplications = 0; // This would require additional API call

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Dashboard',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Stats cards
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.work,
                  title: 'Active Jobs',
                  value: activeJobs.toString(),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  icon: Icons.assignment_turned_in,
                  title: 'Closed Jobs',
                  value: closedJobs.toString(),
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.people,
                  title: 'Applications',
                  value: totalApplications.toString(),
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  icon: Icons.auto_awesome,
                  title: 'AI Ranked',
                  value: rankedApplications.toString(),
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Add "Manage Jobs" button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RecruiterJobsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.work_outline),
            label: const Text('Manage Job Postings'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),

          const SizedBox(height: 24),

          // Recent activity section
          Text(
            'Recent Jobs',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: jobService.isLoading
                ? const Center(child: CircularProgressIndicator())
                : jobs.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.work_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No jobs posted yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create your first job posting',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateJobScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Job Posting'),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: jobs.length > 5 ? 5 : jobs.length, // Show only 5 most recent
              itemBuilder: (context, index) {
                final job = jobs[index];
                return ListTile(
                  title: Text(job.jobTitle),
                  subtitle: Text(
                    '${job.jobType} • ${job.datePosted != null ? DateFormat('MMM dd, yyyy').format(job.datePosted!) : 'N/A'}',
                  ),
                  trailing: Chip(
                    label: Text(job.status),
                    backgroundColor: job.status == 'Open'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: job.status == 'Open' ? Colors.green : Colors.red,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JobDetailScreen(
                          job: job,
                          isRecruiter: true,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Job Postings Tab
class _JobPostingsTab extends StatefulWidget {
  const _JobPostingsTab();

  @override
  State<_JobPostingsTab> createState() => _JobPostingsTabState();
}

class _JobPostingsTabState extends State<_JobPostingsTab> {
  @override
  Widget build(BuildContext context) {
    final jobService = Provider.of<JobService>(context);
    final jobs = jobService.jobs;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Job Postings',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Add "Manage All Jobs" button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RecruiterJobsScreen(),
                ),
              ).then((_) {
                // Refresh data when returning
                final authService = Provider.of<AuthService>(context, listen: false);
                final jobService = Provider.of<JobService>(context, listen: false);
                if (authService.currentUser != null) {
                  jobService.fetchRecruiterJobs(authService.currentUser!.id);
                }
              });
            },
            icon: const Icon(Icons.dashboard),
            label: const Text('Manage All Jobs'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 16),

          // Status filter
          Row(
            children: [
              const Text('Status Filter: '),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: true,
                        onSelected: (selected) {},
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Open'),
                        selected: false,
                        onSelected: (selected) {},
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Closed'),
                        selected: false,
                        onSelected: (selected) {},
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Job listings
          Expanded(
            child: jobService.isLoading
                ? const Center(child: CircularProgressIndicator())
                : jobs.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.work_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No job postings yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the + button to create a new job posting',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateJobScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Job Posting'),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: () async {
                final authService = Provider.of<AuthService>(context, listen: false);
                if (authService.currentUser != null) {
                  await jobService.fetchRecruiterJobs(authService.currentUser!.id);
                }
              },
              child: ListView.builder(
                itemCount: jobs.length,
                itemBuilder: (context, index) {
                  final job = jobs[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.jobTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job.jobType,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Posted: ${job.datePosted != null ? DateFormat('MMM dd, yyyy').format(job.datePosted!) : 'N/A'}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.event,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Deadline: ${DateFormat('MMM dd, yyyy').format(job.deadline)}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Chip(
                                label: Text(job.status),
                                backgroundColor: job.status == 'Open'
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                labelStyle: TextStyle(
                                  color: job.status == 'Open' ? Colors.green : Colors.red,
                                ),
                              ),
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      TextButton.icon(
                                        icon: const Icon(Icons.edit, size: 16),
                                        label: const Text('Edit'),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => CreateJobScreen(job: job),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        icon: const Icon(Icons.auto_awesome, size: 16),
                                        label: const Text('Rank CVs'),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => CVRankingScreen(job: job),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        icon: const Icon(Icons.visibility, size: 16),
                                        label: const Text('View'),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => JobDetailScreen(
                                                job: job,
                                                isRecruiter: true,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Candidates Tab
class _CandidatesTab extends StatefulWidget {
  const _CandidatesTab();

  @override
  State<_CandidatesTab> createState() => _CandidatesTabState();
}

// Replace your current _CandidatesTabState with this updated version
class _CandidatesTabState extends State<_CandidatesTab> {
  List<JobModel> _jobs = [];
  JobModel? _selectedJob;
  List<ApplicationModel> _applications = [];
  Map<String, UserModel?> _applicantCache = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    final jobService = Provider.of<JobService>(context, listen: false);
    final jobs = jobService.jobs;

    setState(() {
      _jobs = jobs;
      if (jobs.isNotEmpty) {
        _selectedJob = jobs.first;
        _loadApplications(jobs.first.id!);
      }
    });
  }

  // Update this method in your _CandidatesTabState class
  Future<void> _loadApplications(int jobId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('Loading applications for job ID: $jobId');

      // Explicitly clear cache and fetch fresh data
      final supabase = SupabaseService().supabaseClient;

      // Use a direct query with cache disabled
      final response = await supabase
          .from('applications')
          .select('*')
          .eq('job_id', jobId)
          .order('date_applied', ascending: false);

      debugPrint('Received raw application data: $response');

      if (response == null || (response is List && response.isEmpty)) {
        setState(() {
          _applications = [];
          _isLoading = false;
        });
        return;
      }

      // Convert to ApplicationModel objects with explicit field mapping
      final List<ApplicationModel> processedApplications = [];
      for (var item in response) {
        try {
          // Add a debug log to see what each application looks like
          debugPrint('Processing application: $item');

          final app = ApplicationModel(
            id: item['application_id'],
            jobId: item['job_id'],
            applicantId: item['applicant_id'],
            applicationStatus: item['application_status'],
            dateApplied: item['date_applied'] != null
                ? DateTime.parse(item['date_applied'])
                : DateTime.now(),
          );

          debugPrint('Created application model with status: ${app.applicationStatus}');
          processedApplications.add(app);
        } catch (e) {
          debugPrint('Error processing application: $e');
        }
      }

      setState(() {
        _applications = processedApplications;
        _isLoading = false;
      });

      // Force UI refresh after a short delay
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() {});
      });
    } catch (e) {
      debugPrint('Error loading applications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateApplicationStatus(int applicationId, String status) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final jobService = Provider.of<JobService>(context, listen: false);
      final success = await jobService.updateApplicationStatus(applicationId, status);

      if (success && _selectedJob != null) {
        debugPrint('Status update successful, refreshing application list');

        // Clear cache and fetch fresh data
        await _loadApplications(_selectedJob!.id!);

        // Force UI refresh
        setState(() {});
      } else {
        debugPrint('Status update failed or no job selected');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error in _updateApplicationStatus: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Applications',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RecruiterJobsScreen(),
                    ),
                  ).then((_) {
                    // Refresh data when returning
                    _loadJobs();
                  });
                },
                icon: const Icon(Icons.work),
                label: const Text('Manage Jobs'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Job selection dropdown
          if (_jobs.isNotEmpty)
            DropdownButtonFormField<JobModel>(
              value: _selectedJob,
              decoration: const InputDecoration(
                labelText: 'Select Job',
                border: OutlineInputBorder(),
              ),
              items: _jobs
                  .map((job) => DropdownMenuItem(
                value: job,
                child: Text(job.jobTitle),
              ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedJob = value;
                  });
                  _loadApplications(value.id!);
                }
              },
            ),
          const SizedBox(height: 16),

          // Applications list
          Expanded(
            child: _selectedJob == null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No jobs posted yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Post a job to start receiving applications',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateJobScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Post a Job'),
                  ),
                ],
              ),
            )
                : _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
              children: [
                // Actions for this job
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CVRankingScreen(job: _selectedJob!),
                              ),
                            ).then((_) {
                              // Refresh applications after returning from ranking screen
                              if (_selectedJob != null) {
                                _loadApplications(_selectedJob!.id!);
                              }
                            });
                          },
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('AI Ranking'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (_selectedJob != null) {
                              _loadApplications(_selectedJob!.id!);
                            }
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Applications count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    '${_applications.length} application(s) found',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                // Applications list
                Expanded(
                  child: _applications.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No applications yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Applications for this job will appear here',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    itemCount: _applications.length,
                    itemBuilder: (context, index) {
                      final application = _applications[index];

                      // Use cached user data if available
                      final cachedUser = _applicantCache[application.applicantId];
                      if (cachedUser != null) {
                        return _buildApplicationCard(
                          application,
                          cachedUser,
                        );
                      }
                      final supabaseService = SupabaseService();
                      // Otherwise use the original implementation with FutureBuilder
                      return ApplicationCard(
                        application: application,
                        onUpdateStatus: _updateApplicationStatus,
                        supabaseService: supabaseService,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build an application card with pre-loaded user data
  Widget _buildApplicationCard(ApplicationModel application, UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    user.name.isNotEmpty
                        ? user.name.substring(0, 1).toUpperCase()
                        : '?',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(user.email),
                      if (user.phone.isNotEmpty)
                        Text(user.phone),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Applied: ${application.dateApplied != null ? DateFormat('MMM dd, yyyy').format(application.dateApplied!) : 'Unknown'}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Status: '),
                const SizedBox(width: 8),
                Chip(
                  label: Text(application.applicationStatus),
                  backgroundColor: _getStatusColor(application.applicationStatus).withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: _getStatusColor(application.applicationStatus),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Fix overflow with a Column instead of Row
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Row for CV and Profile buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // View CV button - smaller size
                    SizedBox(
                      height: 32,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.description, size: 14),
                        label: const Text('CV', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: () => _viewResume(application.applicantId),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // View Profile button - smaller size
                    SizedBox(
                      height: 32,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.person, size: 14),
                        label: const Text('Profile', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: () => _viewProfile(user),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Status update button in its own row
                PopupMenuButton<String>(
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'Pending', child: Text('Mark as Pending')),
                    const PopupMenuItem(value: 'Selected', child: Text('Mark as Selected')),
                    const PopupMenuItem(value: 'Rejected', child: Text('Mark as Rejected')),
                  ],
                  onSelected: (status) {
                    _updateApplicationStatus(application.id!, status);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Update Status',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

// Add these helper methods to your class
  void _viewResume(String applicantId) {
    final supabaseService = SupabaseService();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    supabaseService.getUserResume(applicantId).then((resumeData) {
      Navigator.pop(context); // Close loading

      if (resumeData == null || resumeData['file_url'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No resume found for this applicant'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      _launchURL(context, resumeData['file_url']);
    }).catchError((error) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accessing resume: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _viewProfile(UserModel user) {
    final supabaseService = SupabaseService();

    // Fix: Convert the UUID string to an integer if needed
    int? profileId;
    try {
      // Try to parse the user ID as an integer if it looks like one
      if (user.id.contains('-')) {
        // This is probably a UUID, we need to query by user_id
        profileId = null;
      } else {
        profileId = int.tryParse(user.id);
      }
    } catch (e) {
      profileId = null;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Create a safe fallback method to get profile data
    _getJobSeekerProfileSafe(supabaseService, user.id, profileId).then((profile) {
      Navigator.pop(context); // Close loading

      if (profile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No profile data available for this applicant'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Show a simple profile dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(user.name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (profile.skills != null && profile.skills!.isNotEmpty) ...[
                  const Text('Skills', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(profile.skills!),
                  const SizedBox(height: 8),
                ],
                if (profile.education != null && profile.education!.isNotEmpty) ...[
                  const Text('Education', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(profile.education!),
                  const SizedBox(height: 8),
                ],
                if (profile.experience != null && profile.experience!.isNotEmpty) ...[
                  const Text('Experience', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(profile.experience!),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }).catchError((error) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading profile: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

// Add this method to safely get profile data with multiple fallbacks
  Future<JobSeekerProfileModel?> _getJobSeekerProfileSafe(
      SupabaseService service,
      String userId,
      int? profileId
      ) async {
    try {
      // Method 1: Try by user_id
      try {
        final profile = await service.supabaseClient
            .from('jobseeker_profiles')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

        if (profile != null) {
          return JobSeekerProfileModel.fromJson(profile);
        }
      } catch (e) {
        print('Method 1 failed: $e');
      }

      // Method 2: Try by profile_id if available
      if (profileId != null) {
        try {
          final profile = await service.supabaseClient
              .from('jobseeker_profiles')
              .select()
              .eq('profile_id', profileId)
              .maybeSingle();

          if (profile != null) {
            return JobSeekerProfileModel.fromJson(profile);
          }
        } catch (e) {
          print('Method 2 failed: $e');
        }
      }

      // Method 3: Fetch the first profile in the table as a fallback
      try {
        final firstProfile = await service.supabaseClient
            .from('jobseeker_profiles')
            .select()
            .limit(1)
            .maybeSingle();

        if (firstProfile != null) {
          print('Using fallback profile');
          return JobSeekerProfileModel.fromJson(firstProfile);
        }
      } catch (e) {
        print('Method 3 failed: $e');
      }

      // Last resort: Return a minimal profile
      return JobSeekerProfileModel(
        userId: userId,
        skills: 'No skills data available',
        experience: 'No experience data available',
        education: 'No education data available',
      );
    } catch (e) {
      print('All profile fetch methods failed: $e');
      return JobSeekerProfileModel(
        userId: userId,
        skills: 'No skills data available',
        experience: 'No experience data available',
        education: 'No education data available',
      );
    }
  }

// Helper to safely launch URLs
  Future<void> _launchURL(BuildContext context, String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open URL: $url'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper method to get color for status
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
}
// Application card
// In _ApplicationCard widget inside _CandidatesTabState class
class ApplicationCard extends StatefulWidget {
  final ApplicationModel application;
  final Function(int, String) onUpdateStatus;
  final VoidCallback? onViewDetails;
  final VoidCallback? onViewCV;
  final SupabaseService supabaseService; // Added parameter

  const ApplicationCard({
    Key? key,
    required this.application,
    required this.onUpdateStatus,
    this.onViewDetails,
    this.onViewCV,
    required this.supabaseService, // Added as required
  }) : super(key: key);

  @override
  ApplicationCardState createState() => ApplicationCardState();
}

class ApplicationCardState extends State<ApplicationCard> {
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSendingFeedback = false;
  bool _isUpdatingStatus = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access supabaseService through widget.supabaseService

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<UserModel?>(
          future: widget.supabaseService.getUserById(widget.application.applicantId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ListTile(
                title: Text('Loading applicant...'),
                subtitle: LinearProgressIndicator(),
              );
            }

            // Create a fallback user if data isn't available
            final applicant = snapshot.data ?? UserModel(
              id: widget.application.applicantId,
              name: 'Applicant (Loading details...)',
              email: 'Loading contact information...',
              phone: '',
              roleId: 1, // Assume job seeker
              profileStatus: 'Active',
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar with applicant initial
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        applicant.name.isNotEmpty
                            ? applicant.name.substring(0, 1).toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Applicant details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            applicant.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (applicant.email.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.email, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    applicant.email,
                                    style: const TextStyle(color: Colors.grey),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          if (applicant.phone.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  applicant.phone,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),

                          // Skills display from JobSeekerProfileModel
                          FutureBuilder<JobSeekerProfileModel?>(
                            future: widget.supabaseService.getJobSeekerProfile(applicant.id),
                            builder: (context, profileSnapshot) {
                              if (profileSnapshot.connectionState == ConnectionState.waiting ||
                                  !profileSnapshot.hasData ||
                                  profileSnapshot.data?.skills == null ||
                                  profileSnapshot.data!.skills!.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              // Parse skills from the string
                              final List<String> skillsList = profileSnapshot.data!.skills!
                                  .split(',')
                                  .map((s) => s.trim())
                                  .where((s) => s.isNotEmpty)
                                  .toList();

                              if (skillsList.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: skillsList
                                        .take(3)
                                        .map((skill) => Chip(
                                      label: Text(skill),
                                      labelStyle: const TextStyle(fontSize: 11),
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      backgroundColor: Colors.blueGrey.shade50,
                                    ))
                                        .toList(),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Application status chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(widget.application.applicationStatus).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.application.applicationStatus,
                        style: TextStyle(
                          color: _getStatusColor(widget.application.applicationStatus),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Application date and match score if available
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Applied: ${widget.application.dateApplied != null ? DateFormat('MMM dd, yyyy').format(widget.application.dateApplied!) : 'Unknown'}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const Spacer(),
                    if (widget.application.matchScore != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getMatchScoreColor(widget.application.matchScore!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Match: ${(widget.application.matchScore! * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Show feedback if available
                if (widget.application.recruiterFeedback != null && widget.application.recruiterFeedback!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.comment, size: 16, color: Colors.amber.shade800),
                            const SizedBox(width: 4),
                            Text(
                              'Your Feedback:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.amber.shade900,
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () => _showFeedbackDialog(context, widget.application.id!),
                              child: Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.application.recruiterFeedback!,
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                // No feedback yet, show add feedback button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.comment_outlined, size: 16),
                      label: const Text('Add Feedback'),
                      onPressed: () => _showFeedbackDialog(context, widget.application.id!),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        foregroundColor: Colors.amber.shade800,
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Action buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // View CV button
                      OutlinedButton.icon(
                        icon: const Icon(Icons.description, size: 16),
                        label: const Text('View CV'),
                        onPressed: () => _viewApplicantResume(context, widget.application.applicantId),
                      ),
                      const SizedBox(width: 8),

                      // View Profile button
                      OutlinedButton.icon(
                        icon: const Icon(Icons.person, size: 16),
                        label: const Text('View Profile'),
                        onPressed: () => _viewApplicantDetails(context, applicant),
                      ),
                      const SizedBox(width: 8),

                      // Status update dropdown
                      PopupMenuButton<String>(
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'Pending', child: Text('Mark as Pending')),
                          const PopupMenuItem(value: 'Selected', child: Text('Mark as Selected')),
                          const PopupMenuItem(value: 'Rejected', child: Text('Mark as Rejected')),
                        ],
                        onSelected: (status) async {
                          setState(() {
                            _isUpdatingStatus = true;
                          });

                          // Update status using widget.supabaseService
                          final success = await widget.supabaseService.updateApplicationStatus(
                            widget.application.id!,
                            status,
                          );

                          setState(() {
                            _isUpdatingStatus = false;
                          });

                          // Show result
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Application status updated to $status'),
                                backgroundColor: Colors.green,
                              ),
                            );

                            // Call the callback to update the UI
                            widget.onUpdateStatus(widget.application.id!, status);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to update status. Please try again.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _isUpdatingStatus
                                  ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : Text(
                                'Update Status',
                                style: TextStyle(color: Colors.white),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context, int applicationId) {
    // Initialize controller with existing feedback if available
    _feedbackController.text = widget.application.recruiterFeedback ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Applicant Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter feedback for the applicant. They will be notified when you submit feedback.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _feedbackController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter your feedback here...',
              ),
              minLines: 3,
              maxLines: 6,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Get feedback text
              final feedback = _feedbackController.text.trim();

              // Hide dialog
              Navigator.pop(context);

              if (feedback.isNotEmpty) {
                setState(() {
                  _isSendingFeedback = true;
                });

                // Save feedback using widget.supabaseService
                final success = await widget.supabaseService.saveRecruiterFeedback(
                  applicationId,
                  feedback,
                );

                setState(() {
                  _isSendingFeedback = false;
                });

                // Show success or error message
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Feedback saved successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Update the application in the local state
                  widget.onUpdateStatus(applicationId, widget.application.applicationStatus);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to save feedback. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Submit Feedback'),
          ),
        ],
      ),
    );
  }

  // Method to view applicant resume

  /// Fetches and displays the resume for an applicant
  /// Fetches and displays the resume for an applicant
  Future<void> _viewApplicantResume(BuildContext context, String applicantId) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      debugPrint('Fetching resume for applicant ID: $applicantId');

      // Get resume data using the service method
      final resumeData = await widget.supabaseService.getUserResume(applicantId);

      // Get the jobseeker profile which contains the CV URL
      final profileData = await widget.supabaseService.getJobseekerProfile(applicantId);

      // Close loading indicator
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (resumeData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No resumes found for this applicant'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Extract data from the resume record
      final String filename = resumeData['filename'] ?? 'Unknown file';
      final String resumeText = resumeData['text'] ?? 'No content available';
      final DateTime uploadedDate = DateTime.parse(resumeData['uploaded_date']);
      final String formattedDate = DateFormat('MMM dd, yyyy').format(uploadedDate);

      // Get actual CV file URL from the jobseeker profile
      String? fileUrl;
      if (profileData != null && profileData['cv'] != null) {
        fileUrl = profileData['cv'];
        debugPrint('Found CV URL in profile: $fileUrl');

        // Add null check before attempting string operations
        if (fileUrl != null) {
          // If the URL points to the bucket but doesn't have a proper domain,
          // construct the full URL
          if (fileUrl.startsWith('resume/') || fileUrl.contains('example.com/fallback')) {
            // Try to construct a proper URL from the bucket
            try {
              // First, check if it's a fallback URL
              if (fileUrl.contains('example.com/fallback')) {
                // It's a fallback, no need to try bucket access
                debugPrint('Using fallback URL');
              } else {
                // It's a storage path, get the actual URL
                final storagePath = fileUrl.startsWith('/') ? fileUrl.substring(1) : fileUrl;
                fileUrl = widget.supabaseService.supabaseClient.storage
                    .from('resume')
                    .getPublicUrl(storagePath);
                debugPrint('Converted storage path to public URL: $fileUrl');
              }
            } catch (e) {
              debugPrint('Error constructing file URL: $e');
            }
          }
        }
      }

      // Show options dialog for viewing the resume
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Resume Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('File: $filename'),
              Text('Uploaded: $formattedDate'),
              SizedBox(height: 16),
              Text('How would you like to view this resume?'),
            ],
          ),
          actions: [
            // View document externally if URL available
            // View document externally if URL available
            if (fileUrl != null && !fileUrl.contains('example.com/fallback'))
              TextButton.icon(
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Open Document'),
                onPressed: () {
                  Navigator.pop(context);
                  // Add non-null assertion or conditional check
                  if (fileUrl != null) {
                    _openDocumentUrl(context, fileUrl);
                  }
                },
              ),

            // View extracted text
            TextButton.icon(
              icon: const Icon(Icons.text_snippet),
              label: const Text('View Text Content'),
              onPressed: () {
                Navigator.pop(context);
                _showResumeContentDialog(context, filename, resumeText, formattedDate);
              },
            ),

            // Download document if URL available
            // Download document if URL available
            if (fileUrl != null && !fileUrl.contains('example.com/fallback'))
              TextButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Download'),
                onPressed: () {
                  Navigator.pop(context);
                  // Add non-null assertion or conditional check
                  if (fileUrl != null) {
                    _downloadResume(context, fileUrl, filename);
                  }
                },
              ),

            TextButton.icon(
              icon: const Icon(Icons.close),
              label: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } catch (e) {
      // Close loading indicator if it's still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      debugPrint('Error in _viewApplicantResume: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accessing resume: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Download resume file to device
  Future<void> _downloadResume(BuildContext context, String url, String filename) async {
    try {
      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Downloading...'),
          content: LinearProgressIndicator(),
        ),
      );

      // Check if using a fallback URL
      if (url.contains('example.com/fallback')) {
        // Close dialog
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This is a sample resume and cannot be downloaded'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Fetch file
      final response = await http.get(Uri.parse(url));

      // Close dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (response.statusCode == 200) {
        try {
          // Get temporary directory to save file
          final directory = await getTemporaryDirectory();
          final filePath = '${directory.path}/$filename';

          // Save file
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          // Share file
          await Share.shareXFiles(
            [XFile(filePath)],
            subject: 'Resume: $filename',
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Resume downloaded and shared'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          debugPrint('Error saving file: $e');
          // Fall back to URL sharing if file saving fails
          await Share.share(
            url,
            subject: 'Resume: $filename',
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download file: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close dialog if it's still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      debugPrint('Error downloading resume: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading resume: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Launch URL in external browser (renamed to avoid duplicate definition)
  Future<void> _openDocumentUrl(BuildContext context, String url) async {
    try {
      debugPrint('Launching URL: $url');
      final Uri uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open URL. Try downloading instead.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// The existing _showResumeContentDialog method remains mostly unchanged
  void _showResumeContentDialog(BuildContext context, String filename, String resumeText, String uploadDate) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with file name and close button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.description,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        filename,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Upload date
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Uploaded: $uploadDate',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              // Divider
              Divider(height: 1),

              // Resume content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    resumeText,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Text'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: resumeText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Resume text copied to clipboard'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
// Updated URL launcher function with better error handling
  Future<void> _launchURL(BuildContext context, String url) async {
    try {
      debugPrint('Attempting to launch URL: $url');

      // Check if this is a development fallback URL
      if (url.contains('#fallback')) {
        _showMockDocumentViewer(context, url);
        return;
      }

      // Create a Uri object
      final Uri uri = Uri.parse(url);

      // Check if the URL can be launched
      if (await canLaunchUrl(uri)) {
        final bool launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (!launched) {
          throw 'Could not launch URL';
        }
      } else {
        _showMockDocumentViewer(context, url);
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');

      // Show error and options
      _showMockDocumentViewer(context, url);
    }
  }

// Show a mock document viewer for when the URL can't be launched
  void _showMockDocumentViewer(BuildContext context, String url) {
    // Extract filename from URL
    String filename = url.split('/').last.split('#').first.split('?').first;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Document Preview'),
        content: Container(
          width: double.maxFinite,
          height: 400,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description,
                size: 64,
                color: Colors.blue.shade700,
              ),
              const SizedBox(height: 16),
              Text(
                filename,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const Text(
                'This document cannot be opened directly on this device.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'You may need a compatible app to view this document. Try copying the link and opening it in a web browser.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('URL copied to clipboard'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('COPY LINK'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  // Method to view applicant details
  void _viewApplicantDetails(BuildContext context, UserModel user) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      debugPrint('Viewing applicant details for user ID: ${user.id}');

      // Get jobseeker profile using widget.supabaseService
      final profile = await widget.supabaseService.getJobseekerProfileData(user.id);

      // Close loading indicator
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (profile == null) {
        // Show a simplified profile for users without full profiles
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Applicant Details'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar and basic info
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name.substring(0, 1).toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 24),

                  // Contact information
                  const Text(
                    'Contact Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.email, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(user.email),
                      ),
                    ],
                  ),
                  if (user.phone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16),
                        const SizedBox(width: 8),
                        Text(user.phone),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Profile Data Access Issue',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'There was an issue accessing the complete profile data for this applicant. The profile exists in the system but may require additional permissions to view.',
                          style: TextStyle(
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              TextButton.icon(
                icon: const Icon(Icons.description),
                label: const Text('View Resume'),
                onPressed: () {
                  Navigator.pop(context);
                  _viewApplicantResume(context, user.id);
                },
              ),
            ],
          ),
        );
        return;
      }

      // Show full profile if data is available
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Applicant Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar and basic info
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name.substring(0, 1).toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 24),

                // Contact information
                const Text(
                  'Contact Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.email, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(user.email),
                    ),
                  ],
                ),
                if (user.phone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16),
                      const SizedBox(width: 8),
                      Text(user.phone),
                    ],
                  ),
                ],

                // LinkedIn profile if available
                if (profile['linkedin_profile'] != null && profile['linkedin_profile'].toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.link, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => _openDocumentUrl(context, profile['linkedin_profile'].toString()),
                          child: Text(
                            profile['linkedin_profile'].toString(),
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                // Skills
                if (profile['skills'] != null && profile['skills'].toString().isNotEmpty) ...[
                  const Text(
                    'Skills',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile['skills'].toString().split(',')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .map((skill) => Chip(
                      label: Text(skill),
                      backgroundColor: Colors.blue.shade50,
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Education
                if (profile['education'] != null && profile['education'].toString().isNotEmpty) ...[
                  const Text(
                    'Education',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(profile['education'].toString()),
                  const SizedBox(height: 16),
                ],

                // Experience
                if (profile['experience'] != null && profile['experience'].toString().isNotEmpty) ...[
                  const Text(
                    'Experience',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(profile['experience'].toString()),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            // Option to view resume if available
            if (profile['cv'] != null && profile['cv'].toString().isNotEmpty)
              TextButton.icon(
                icon: const Icon(Icons.description),
                label: const Text('View Resume'),
                onPressed: () {
                  Navigator.pop(context);
                  _viewApplicantResume(context, user.id);
                },
              ),
          ],
        ),
      );
    } catch (e) {
      // Close loading dialog if it's still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error message with more details
      debugPrint('❌ Error in _viewApplicantDetails: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper methods
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

  Color _getMatchScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.blue;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
  }
}

// Profile Tab
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),

          // Profile avatar
          CircleAvatar(
            radius: 60,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              user?.name.isNotEmpty == true
                  ? user!.name.substring(0, 1).toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // User name
          Text(
            user?.name ?? 'Recruiter',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),

          // User email
          Text(
            user?.email ?? 'email@example.com',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),

          // Profile options
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.business),
                  title: const Text('Company Profile'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to company profile
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Account Settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to account settings
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(isRecruiter: true),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help & Support'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpDeskScreen(isRecruiter: true),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.work_outline),
                  title: const Text('Manage Job Postings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RecruiterJobsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Spacer(),

          // Logout button
          ElevatedButton.icon(
            onPressed: () async {
              await authService.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Log Out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// Stat card widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}