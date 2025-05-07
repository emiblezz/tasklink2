// lib/screens/recruiter/recruiter_jobs_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasklink2/models/job_model.dart';
import 'package:tasklink2/screens/job_detail_screen.dart';
import 'package:tasklink2/screens/recruiter/create_job_screen.dart';
import 'package:tasklink2/services/auth_service.dart';
import 'package:tasklink2/services/job_service.dart';
import 'package:tasklink2/widgets/job_card.dart'; // Make sure to create this file

class RecruiterJobsScreen extends StatefulWidget {
  const RecruiterJobsScreen({Key? key}) : super(key: key);

  @override
  State<RecruiterJobsScreen> createState() => _RecruiterJobsScreenState();
}

class _RecruiterJobsScreenState extends State<RecruiterJobsScreen> {
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final jobService = Provider.of<JobService>(context, listen: false);

    if (authService.currentUser != null) {
      await jobService.fetchRecruiterJobs(authService.currentUser!.id);
    }
  }

  List<JobModel> _getFilteredJobs(List<JobModel> jobs) {
    if (_statusFilter == null) {
      return jobs;
    }
    return jobs.where((job) => job.status == _statusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final jobService = Provider.of<JobService>(context);
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    if (user == null) {
      return const Center(child: Text('Please login to view your job postings'));
    }

    final filteredJobs = _getFilteredJobs(jobService.jobs);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Job Postings'),
        actions: [
          PopupMenuButton<String?>(
            onSelected: (value) {
              setState(() {
                if (value == 'all') {
                  _statusFilter = null;
                } else {
                  _statusFilter = value;
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Jobs'),
              ),
              const PopupMenuItem(
                value: 'Open',
                child: Text('Open Jobs'),
              ),
              const PopupMenuItem(
                value: 'Closed',
                child: Text('Closed Jobs'),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: const [
                  Text('Filter'),
                  Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadJobs,
        child: jobService.isLoading
            ? const Center(child: CircularProgressIndicator())
            : filteredJobs.isEmpty
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
                _statusFilter != null
                    ? 'No ${_statusFilter!.toLowerCase()} jobs found'
                    : 'No jobs found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Create a new job posting to get started',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateJobScreen(),
                    ),
                  ).then((result) {
                    if (result == true) {
                      _loadJobs();
                    }
                  });
                },
                child: const Text('Create Job'),
              ),
            ],
          ),
        )
            : ListView.builder(
          itemCount: filteredJobs.length,
          itemBuilder: (context, index) {
            final job = filteredJobs[index];
            return Dismissible(
              key: Key('job-${job.id}'),
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Job'),
                    content: const Text(
                      'Are you sure you want to delete this job? '
                          'This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                ) ?? false;
              },
              onDismissed: (direction) async {
                await jobService.deleteJob(job.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Job deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: JobCard(
                job: job,
                isDismissible: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JobDetailScreen(
                        job: job,
                        isRecruiter: true,
                      ),
                    ),
                  ).then((value) {
                    if (value == true) {
                      _loadJobs();
                    }
                  });
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateJobScreen()),
          ).then((result) {
            if (result == true) {
              _loadJobs();
            }
          });
        },
        child: const Icon(Icons.add),
        tooltip: 'Post a New Job',
      ),
    );
  }
}