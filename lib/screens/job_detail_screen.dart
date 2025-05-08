import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tasklink2/models/job_model.dart';
import 'package:tasklink2/services/auth_service.dart';
import 'package:tasklink2/services/job_service.dart';
import 'package:tasklink2/screens/recruiter/create_job_screen.dart';
import 'package:tasklink2/screens/recruiter/cv_ranking_screen.dart';
import 'package:tasklink2/config/app_config.dart';

class JobDetailScreen extends StatefulWidget {
  final JobModel job;
  final bool isRecruiter;
  final bool showFeedback;
  final int? applicationId;

  const JobDetailScreen({
    super.key,
    required this.job,
    this.isRecruiter = false,
    this.showFeedback = false,
    this.applicationId,
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _isApplying = false;
  bool _isLoadingFeedback = false;
  String? _recruiterFeedback;
  String? _applicationStatus;

  @override
  void initState() {
    super.initState();
    _checkApplicationStatus();

    if (widget.showFeedback && widget.applicationId != null) {
      _loadFeedback();
    }
  }

  // Check if user has already applied
  Future<void> _checkApplicationStatus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser == null || widget.isRecruiter) return;

    try {
      // Check if user has already applied using Supabase directly
      final response = await AppConfig().supabaseClient
          .from('applications')
          .select('application_status')
          .eq('job_id', widget.job.id)
          .eq('applicant_id', authService.currentUser!.id)
          .maybeSingle();

      if (mounted && response != null) {
        setState(() {
          _applicationStatus = response['application_status'] as String;
        });
      }
    } catch (e) {
      print('Error checking application status: $e');
    }
  }

  // Load recruiter feedback for this application
  Future<void> _loadFeedback() async {
    setState(() {
      _isLoadingFeedback = true;
    });

    try {
      // Fetch the application with the feedback
      final response = await AppConfig().supabaseClient
          .from('applications')
          .select('recruiter_feedback, application_status')
          .eq('application_id', widget.applicationId)
          .single();

      setState(() {
        _recruiterFeedback = response['recruiter_feedback'];
        _applicationStatus = response['application_status'];
        _isLoadingFeedback = false;
      });

      // Show dialog with feedback after a short delay
      if (_recruiterFeedback != null && _recruiterFeedback!.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showFeedbackDialog();
          }
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingFeedback = false;
      });
      print('Error loading feedback: $e');
    }
  }

  Future<void> _applyForJob() async {
    setState(() {
      _isApplying = true;
    });

    try {
      final jobService = Provider.of<JobService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      if (authService.currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You must be logged in to apply for jobs'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final result = await jobService.applyForJob(
        widget.job.id!,
        authService.currentUser!.id,
      );

      if (mounted) {
        if (result != null) {
          setState(() {
            _applicationStatus = 'Pending';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Application submitted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(jobService.errorMessage ?? 'Failed to apply for job'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isApplying = false;
        });
      }
    }
  }

  Future<void> _editJob() async {
    if (!widget.isRecruiter) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateJobScreen(job: widget.job),
      ),
    );

    if (result == true && mounted) {
      // Refresh job details
      JobService jobService = Provider.of<JobService>(context, listen: false);
      await jobService.fetchRecruiterJobs(widget.job.recruiterId);
    }
  }

  // Method to view applicants and rankings
  Future<void> _viewApplicants() async {
    if (!widget.isRecruiter) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CVRankingScreen(job: widget.job),
      ),
    );

    if (result == true && mounted) {
      // Refresh job details if needed
      JobService jobService = Provider.of<JobService>(context, listen: false);
      await jobService.fetchRecruiterJobs(widget.job.recruiterId);
    }
  }

  Future<void> _closeJob() async {
    if (!widget.isRecruiter) return;

    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Job'),
        content: const Text(
          'Are you sure you want to close this job? '
              'It will no longer be visible to job seekers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Close Job'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final jobService = Provider.of<JobService>(context, listen: false);
      final success = await jobService.closeJob(widget.job.id!);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Job closed successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate job was closed
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(jobService.errorMessage ?? 'Failed to close job'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Simpler dialog for showing feedback
  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.comment, color: Colors.amber),
            SizedBox(width: 8),
            Text('Recruiter Feedback'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_applicationStatus != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(_applicationStatus!).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getStatusColor(_applicationStatus!).withOpacity(0.5),
                  ),
                ),
                child: Text(
                  'Status: $_applicationStatus',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(_applicationStatus!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Container(
              padding: const EdgeInsets.all(16),
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _recruiterFeedback ?? 'No specific feedback provided by the recruiter.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Helper to handle displaying salary with correct currency
  String _formatSalary(dynamic salary) {
    if (salary == null) {
      return 'Not specified';
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

  // Get color based on status
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        actions: widget.isRecruiter
            ? [
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'View Applicants',
            onPressed: _viewApplicants,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Job',
            onPressed: _editJob,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close Job',
            onPressed: _closeJob,
          ),
        ]
            : null,
      ),
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company logo and title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company logo
                    if (widget.job.companyLogo != null && widget.job.companyLogo!.isNotEmpty)
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.job.companyLogo!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Icon(Icons.business, size: 40, color: Colors.grey),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(Icons.business, size: 40, color: Colors.grey),
                        ),
                      ),
                    const SizedBox(width: 16),

                    // Title and company info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.job.jobTitle,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.job.companyName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                widget.job.location,
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Application status for job seekers
                if (!widget.isRecruiter && _applicationStatus != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _getStatusColor(_applicationStatus!).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _getStatusColor(_applicationStatus!).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _applicationStatus == 'Selected' ? Icons.check_circle
                              : _applicationStatus == 'Rejected' ? Icons.cancel
                              : Icons.hourglass_empty,
                          color: _getStatusColor(_applicationStatus!),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Application Status: $_applicationStatus',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: _getStatusColor(_applicationStatus!),
                                ),
                              ),
                              if (_applicationStatus == 'Pending')
                                Text(
                                  'Your application is being reviewed',
                                  style: TextStyle(color: Colors.grey.shade700),
                                )
                              else if (_applicationStatus == 'Selected')
                                Text(
                                  'Congratulations! You have been selected for this position',
                                  style: TextStyle(color: Colors.grey.shade700),
                                )
                              else if (_applicationStatus == 'Rejected')
                                  Text(
                                    'Unfortunately, your application was not selected',
                                    style: TextStyle(color: Colors.grey.shade700),
                                  )
                            ],
                          ),
                        ),
                        if (_recruiterFeedback != null && _recruiterFeedback!.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.comment),
                            tooltip: 'View Recruiter Feedback',
                            color: Colors.amber,
                            onPressed: _showFeedbackDialog,
                          )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Salary information - UPDATED FOR DIFFERENT CURRENCIES
                if (widget.job.salary != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.currency_exchange, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Salary: ${_formatSalary(widget.job.salary)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Job type and status
                Row(
                  children: [
                    Chip(
                      label: Text(widget.job.jobType),
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(widget.job.status),
                      backgroundColor: widget.job.status == 'Open'
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      labelStyle: TextStyle(
                        color: widget.job.status == 'Open' ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Skills section
                if (widget.job.skills != null && widget.job.skills!.isNotEmpty) ...[
                  const Text(
                    'Skills Required',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.job.skills!.map((skill) => Chip(
                      label: Text(skill),
                      backgroundColor: Colors.blue.shade50,
                      labelStyle: TextStyle(
                        color: Colors.blue.shade700,
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Deadline
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Application Deadline: ${DateFormat('MMM dd, yyyy').format(widget.job.deadline)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Posted date
                if (widget.job.datePosted != null)
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Posted: ${DateFormat('MMM dd, yyyy').format(widget.job.datePosted!)}',
                      ),
                    ],
                  ),
                const SizedBox(height: 24),

                // Description section
                const Text(
                  'Job Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(widget.job.description),
                const SizedBox(height: 24),

                // Requirements section
                const Text(
                  'Requirements',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(widget.job.requirements),
                const SizedBox(height: 32),

                // Apply button (only for job seekers, if job is open and not applied)
                if (!widget.isRecruiter && widget.job.status == 'Open' && _applicationStatus == null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isApplying ? null : _applyForJob,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isApplying
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Text(
                        'Apply Now',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                // View Applicants button (for recruiters)
                if (widget.isRecruiter)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _viewApplicants,
                      icon: const Icon(Icons.people),
                      label: const Text('View & Rank Applicants'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                // Applied but no feedback yet (for job seekers)
                if (!widget.isRecruiter && _applicationStatus == 'Pending' && (_recruiterFeedback == null || _recruiterFeedback!.isEmpty))
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(height: 8),
                        const Text(
                          'Your application is under review',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You will be notified when the recruiter makes a decision or provides feedback.',
                          style: TextStyle(color: Colors.grey.shade700),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 40), // Extra space at bottom
              ],
            ),
          ),

          // Loading overlay
          if (_isLoadingFeedback)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}