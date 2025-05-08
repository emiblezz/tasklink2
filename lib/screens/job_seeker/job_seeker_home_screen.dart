import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tasklink2/models/job_model.dart';
import 'package:tasklink2/screens/auth/login_screen.dart';
import 'package:tasklink2/screens/job_detail_screen.dart';
import 'package:tasklink2/screens/job_seeker/edit_profile_screen.dart';
import 'package:tasklink2/services/auth_service.dart';
import 'package:tasklink2/services/job_service.dart';
import 'package:tasklink2/services/profile_service.dart';
import 'package:intl/intl.dart';

import '../../widgets/job_card.dart';
import '../../widgets/notification_badge.dart';
import '../help_desk_screen.dart';
import '../settings_screen.dart';


class JobSeekerHomeScreen extends StatefulWidget {
  const JobSeekerHomeScreen({super.key});

  @override
  State<JobSeekerHomeScreen> createState() => _JobSeekerHomeScreenState();
}

class _JobSeekerHomeScreenState extends State<JobSeekerHomeScreen> {
  int _selectedIndex = 0;
  final _searchController = TextEditingController();
  List<JobModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    final jobService = Provider.of<JobService>(context, listen: false);
    final profileService = Provider.of<ProfileService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    if (authService.currentUser != null) {
      // Load jobs
      await jobService.fetchJobs();

      // Load user profile
      await profileService.fetchProfile(authService.currentUser!.id);

      // Load user applications
      await jobService.fetchUserApplications(authService.currentUser!.id);
    }
  }

  Future<void> _refreshData() async {
    final jobService = Provider.of<JobService>(context, listen: false);

    // Reset search results when refreshing
    setState(() {
      _searchResults = [];
      _searchController.clear();
      _isSearching = false;
    });

    await jobService.fetchJobs();
  }

  Future<void> _searchJobs(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final jobService = Provider.of<JobService>(context, listen: false);
      final results = await jobService.searchJobs(query);

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _viewJobDetails(JobModel job) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobDetailScreen(job: job),
      ),
    );
  }

  Future<void> _editProfile() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    );

    if (result == true) {
      // Refresh profile data
      final profileService = Provider.of<ProfileService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      if (authService.currentUser != null) {
        await profileService.fetchProfile(authService.currentUser!.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pages for bottom navigation
    final List<Widget> _pages = [
      const _JobsTab(),
      const _ApplicationsTab(),
      const _ProfileTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskLink'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(isRecruiter: false),
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
                  builder: (context) => const HelpDeskScreen(isRecruiter: false),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'Applications',
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

// Jobs Tab
class _JobsTab extends StatefulWidget {
  const _JobsTab();

  @override
  State<_JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<_JobsTab> {
  final TextEditingController _searchController = TextEditingController();
  List<JobModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    final jobService = Provider.of<JobService>(context, listen: false);
    await jobService.fetchJobs();
  }

  Future<void> _searchJobs(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final jobService = Provider.of<JobService>(context, listen: false);
      final results = await jobService.searchJobs(query);

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _viewJobDetails(JobModel job) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobDetailScreen(job: job),
      ),
    ).then((_) {
      // Refresh the job list when returning from details
      _loadJobs();
    });
  }

  // In _JobsTabState (in job_seeker_home_screen.dart)
  @override
  Widget build(BuildContext context) {
    final jobService = Provider.of<JobService>(context);
    final List<JobModel> displayJobs = _isSearching
        ? _searchResults
        : jobService.visibleJobs; // Use visibleJobs instead of jobs

    return Column(
      children: [
        // Search bar (keep your existing code)
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for jobs',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _searchJobs('');
                },
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            onChanged: _searchJobs,
          ),
        ),

        // Job listings
        Expanded(
          child: jobService.isLoading
              ? const Center(child: CircularProgressIndicator())
              : displayJobs.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.work_off_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  _isSearching
                      ? 'No jobs found for "${_searchController.text}"'
                      : 'No jobs available',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (!_isSearching)
                  const Text(
                    'Check back later for new opportunities',
                    style: TextStyle(color: Colors.grey),
                  ),
                const SizedBox(height: 24),
                if (_isSearching)
                  ElevatedButton(
                    onPressed: () {
                      _searchController.clear();
                      _searchJobs('');
                    },
                    child: const Text('Clear Search'),
                  ),
                if (jobService.dismissedJobIds.isNotEmpty && !_isSearching)
                  ElevatedButton(
                    onPressed: () {
                      jobService.clearDismissedJobs();
                    },
                    child: const Text('Show Hidden Jobs'),
                  ),
              ],
            ),
          )
              : Stack(
            children: [
              RefreshIndicator(
                onRefresh: _loadJobs,
                child: ListView.builder(
                  itemCount: displayJobs.length,
                  itemBuilder: (context, index) {
                    final job = displayJobs[index];
                    return JobCard(
                      job: job,
                      onTap: () => _viewJobDetails(job),
                      onDismiss: () {
                        jobService.dismissJob(job.id!);
                      },
                    );
                  },
                ),
              ),
              if (jobService.dismissedJobIds.isNotEmpty && !_isSearching)
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      jobService.clearDismissedJobs();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Show All Jobs'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// Applications Tab
class _ApplicationsTab extends StatefulWidget {
  const _ApplicationsTab();

  @override
  State<_ApplicationsTab> createState() => _ApplicationsTabState();
}

class _ApplicationsTabState extends State<_ApplicationsTab> {
  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    final jobService = Provider.of<JobService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    if (authService.currentUser != null) {
      await jobService.fetchUserApplications(authService.currentUser!.id);
    }
  }

  // In the Applications tab in JobSeekerHomeScreen.dart
  @override
  Widget build(BuildContext context) {
    final jobService = Provider.of<JobService>(context);
    final applications = jobService.applications;

    return jobService.isLoading
        ? const Center(child: CircularProgressIndicator())
        : applications.isEmpty
        ? Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No Applications Yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'You haven\'t applied to any jobs yet',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Switch to Jobs tab
              (context.findAncestorStateOfType<_JobSeekerHomeScreenState>())
                  ?.setState(() {
                (context.findAncestorStateOfType<_JobSeekerHomeScreenState>())
                    ?._selectedIndex = 0;
              });
            },
            child: const Text('Browse Jobs'),
          ),
        ],
      ),
    )
        : RefreshIndicator(
      onRefresh: _loadApplications,
      child: ListView.builder(
        itemCount: applications.length,
        itemBuilder: (context, index) {
          final application = applications[index];
          // We need to fetch the job details for each application
          return FutureBuilder<JobModel?>(
            future: jobService.getJobById(application.jobId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text('Loading...'),
                    subtitle: LinearProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: const Text('Error loading job details'),
                    subtitle: const Text('Job may have been removed'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        // Allow deleting applications for removed jobs
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Remove Application'),
                            content: const Text('Remove this application from your list?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Remove'),
                              ),
                            ],
                          ),
                        ) ?? false;

                        if (confirmed && application.id != null) {
                          await jobService.deleteApplication(application.id!);
                          _loadApplications();
                        }
                      },
                    ),
                  ),
                );
              }

              final job = snapshot.data!;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JobDetailScreen(job: job),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and status row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Company logo
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: job.companyLogo != null && job.companyLogo!.isNotEmpty
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  job.companyLogo!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.business,
                                    size: 24,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                                  : const Icon(
                                Icons.business,
                                size: 24,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Job title and company
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    job.jobTitle,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    job.companyName,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Application status
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(application.applicationStatus).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                application.applicationStatus,
                                style: TextStyle(
                                  color: _getStatusColor(application.applicationStatus),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Application date
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'Applied: ${DateFormat('MMM dd, yyyy').format(application.dateApplied ?? DateTime.now())}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
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
    final profileService = Provider.of<ProfileService>(context);
    final user = authService.currentUser;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      // Use ListView instead of Column to make it scrollable
      child: ListView(
        children: [
          const SizedBox(height: 24),

          // Profile avatar
          Center(
            child: CircleAvatar(
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
          ),
          const SizedBox(height: 16),

          // User name
          Center(
            child: Text(
              user?.name ?? 'User',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 4),

          // User email
          Center(
            child: Text(
              user?.email ?? 'email@example.com',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 32),

          // Profile stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ProfileStat(
                icon: Icons.assignment_outlined,
                title: 'Applications',
                value: Provider.of<JobService>(context).applications.length.toString(),
              ),
              _ProfileStat(
                icon: Icons.description_outlined,
                title: 'CV Status',
                value: profileService.profile?.cv != null ? 'Uploaded' : 'Not Uploaded',
                valueColor: profileService.profile?.cv != null
                    ? Colors.green
                    : Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Profile options
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Edit Profile'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('My CV'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Open CV viewer or upload flow
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
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
                        builder: (context) => const SettingsScreen(isRecruiter: false),
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
                        builder: (context) => const HelpDeskScreen(isRecruiter: false),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// Profile stat widget
class _ProfileStat extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  const _ProfileStat({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 24,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Job card widget
class _JobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;

  const _JobCard({
    required this.job,
    required this.onTap,
  });

  // Helper to format salary with currency
  String _formatSalary(dynamic salary) {
    if (salary == null) {
      return 'Salary not specified';
    }

    String salaryText = salary.toString();

    // Check if salary already includes a currency code
    for (String currency in ['UGX', 'USD', 'EUR', 'GBP']) {
      if (salaryText.startsWith('$currency ')) {
        // Already formatted with currency
        return salaryText;
      }
    }

    // Default formatting for numeric values (use local currency)
    try {
      double amount = double.parse(salaryText);
      return NumberFormat.currency(symbol: 'UGX ').format(amount);
    } catch (e) {
      // If not parsable as number, just return the text
      return salaryText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Job title
              Text(
                job.jobTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Company and location row
              Row(
                children: [
                  Icon(Icons.business, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job.companyName,
                      style: TextStyle(color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    job.location,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Job type and salary row
              Row(
                children: [
                  Chip(
                    label: Text(job.jobType),
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                    ),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const Spacer(),
                  if (job.salary != null)
                    Row(
                      children: [
                        Icon(Icons.currency_exchange, size: 14, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text(
                          _formatSalary(job.salary),
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Skills section (limited to 3 for card view)
              if (job.skills != null && job.skills!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: job.skills!.take(3).map((skill) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      skill,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  )).toList(),
                ),

                // Show "more skills" indicator if there are more than 3
                if (job.skills!.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '+${job.skills!.length - 3} more skills',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
              ],

              // Deadline row
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Deadline: ${DateFormat('MMM dd').format(job.deadline)}',
                    style: TextStyle(
                      color: DateTime.now().isAfter(job.deadline.subtract(const Duration(days: 3)))
                          ? Colors.red
                          : Colors.grey[600],
                    ),
                  ),
                  const Spacer(),

                  // Posted date
                  if (job.datePosted != null)
                    Text(
                      'Posted ${_getTimeAgo(job.datePosted!)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM dd, yyyy').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'just now';
    }
  }
}