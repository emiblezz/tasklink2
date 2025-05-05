import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tasklink2/models/application_model.dart';
import 'package:tasklink2/models/job_model.dart';
import 'package:tasklink2/models/user_model.dart';
import 'package:tasklink2/screens/auth/login_screen.dart';
import 'package:tasklink2/screens/job_detail_screen.dart';
import 'package:tasklink2/screens/recruiter/create_job_screen.dart';
import 'package:tasklink2/screens/recruiter/cv_ranking_screen.dart';
import 'package:tasklink2/services/auth_service.dart';
import 'package:tasklink2/services/job_service.dart';
import 'package:tasklink2/services/supabase_service.dart';

import '../../widgets/notification_badge.dart';
import '../help_desk_screen.dart';
import '../settings_screen.dart';


class RecruiterHomeScreen extends StatefulWidget {
  const RecruiterHomeScreen({super.key});

  @override
  State<RecruiterHomeScreen> createState() => _RecruiterHomeScreenState();
}

class _RecruiterHomeScreenState extends State<RecruiterHomeScreen> {
  int _selectedIndex = 0;

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
          const SizedBox(height: 32),

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
      print('Loading applications for job ID: $jobId');

      // Use the simplified query to get all applications
      final supabaseService = SupabaseService();
      final applicationsList = await supabaseService.getJobApplicationsWithProfiles(jobId);

      print('Received ${applicationsList.length} applications');

      if (applicationsList.isEmpty) {
        // Try the fallback method directly
        print('No applications found, trying fallback method');
        //_loadApplicationsFallback(jobId);
        return;
      }

      // Convert to ApplicationModel objects
      final List<ApplicationModel> processedApplications = [];
      for (var item in applicationsList) {
        try {
          final app = ApplicationModel.fromJson(item);
          processedApplications.add(app);
        } catch (e) {
          print('Error converting application data: $e');
        }
      }

      setState(() {
        _applications = processedApplications;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading applications: $e');
      // Fallback to the basic method if the first method fails
      //_loadApplicationsFallback(jobId);
    }
  }

  Future<void> _updateApplicationStatus(int applicationId, String status) async {
    final jobService = Provider.of<JobService>(context, listen: false);
    await jobService.updateApplicationStatus(applicationId, status);

    if (_selectedJob != null) {
      await _loadApplications(_selectedJob!.id!);
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
          Text(
            'Applications',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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

                      // Otherwise use the original implementation with FutureBuilder
                      return _ApplicationCard(
                        application: application,
                        onUpdateStatus: _updateApplicationStatus,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // View CV button (would link to actual CV)
                OutlinedButton.icon(
                  icon: const Icon(Icons.description, size: 16),
                  label: const Text('View CV'),
                  onPressed: () {
                    // Open CV viewer
                  },
                ),
                const SizedBox(width: 8),

                // Status update dropdown
                PopupMenuButton<String>(
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
                  onSelected: (status) {
                    _updateApplicationStatus(application.id!, status);
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
                      children: const [
                        Text(
                          'Update Status',
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(width: 4),
                        Icon(
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
          ],
        ),
      ),
    );
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
class _ApplicationCard extends StatelessWidget {
  final ApplicationModel application;
  final Function(int, String) onUpdateStatus;

  const _ApplicationCard({
    required this.application,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final supabaseService = SupabaseService();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<UserModel?>(
          future: supabaseService.getUserById(application.applicantId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ListTile(
                title: Text('Loading applicant...'),
                subtitle: LinearProgressIndicator(),
              );
            }

            // Create a fallback user if data isn't available
            final applicant = snapshot.data ?? UserModel(
              id: application.applicantId,
              name: 'Applicant (ID: ${application.applicantId.substring(0, 6)}...)',
              email: 'Email not available',
              phone: '',
              roleId: 1, // Assume job seeker
              profileStatus: 'Active',
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        applicant.name.isNotEmpty
                            ? applicant.name.substring(0, 1).toUpperCase()
                            : '?',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            applicant.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(applicant.email),
                          if (applicant.phone.isNotEmpty)
                            Text(applicant.phone),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // View CV button (would link to actual CV)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.description, size: 16),
                      label: const Text('View CV'),
                      onPressed: () {
                        // Open CV viewer
                      },
                    ),
                    const SizedBox(width: 8),

                    // Status update dropdown
                    PopupMenuButton<String>(
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
                      onSelected: (status) {
                        onUpdateStatus(application.id!, status);
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
                          children: const [
                            Text(
                              'Update Status',
                              style: TextStyle(color: Colors.white),
                            ),
                            SizedBox(width: 4),
                            Icon(
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
              ],
            );
          },
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