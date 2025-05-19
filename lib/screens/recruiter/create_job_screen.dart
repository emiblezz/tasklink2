import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tasklink2/models/job_model.dart';
import 'package:tasklink2/services/auth_service.dart';
import 'package:tasklink2/services/job_service.dart';
import 'package:tasklink2/utils/constants.dart';
import 'package:tasklink2/utils/validators.dart';
import 'package:tasklink2/services/image_picker_service.dart';

import '../../config/app_config.dart';
import '../../services/notification_service.dart';

class CreateJobScreen extends StatefulWidget {
  final JobModel? job; // Null for new job, non-null for editing

  const CreateJobScreen({super.key, this.job});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryController = TextEditingController();
  final _skillsController = TextEditingController();

  late String _jobType = 'Full-time';
  late DateTime _deadline = DateTime.now().add(const Duration(days: 30));
  String? _companyLogoUrl;
  bool _isUploading = false;

  // Currency options
  final List<String> _currencies = ['UGX', 'USD', 'EUR', 'GBP'];
  late String _selectedCurrency = 'UGX'; // Default to UGX

  final List<String> _jobTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Internship',
    'Remote'
  ];

  @override
  void initState() {
    super.initState();
    // If job is provided, populate form fields
    if (widget.job != null) {
      _titleController.text = widget.job!.jobTitle;
      _companyNameController.text = widget.job!.companyName;
      _locationController.text = widget.job!.location;
      _descriptionController.text = widget.job!.description;
      _requirementsController.text = widget.job!.requirements;

      // Handle salary (expecting a String in the updated model)
      if (widget.job!.salary != null) {
        final salaryText = widget.job!.salary.toString();
        // Check if salary starts with a currency code
        for (final currency in _currencies) {
          if (salaryText.startsWith('$currency ')) {
            _selectedCurrency = currency;
            _salaryController.text = salaryText.substring(currency.length + 1);
            break;
          }
        }
        // If no currency prefix found, just use the whole value
        if (_salaryController.text.isEmpty) {
          _salaryController.text = salaryText;
        }
      }

      // Skills
      if (widget.job!.skills != null && widget.job!.skills!.isNotEmpty) {
        _skillsController.text = widget.job!.skills!.join(', ');
      }

      _companyLogoUrl = widget.job!.companyLogo;
      _jobType = widget.job!.jobType;
      _deadline = widget.job!.deadline;
    }
  }

  Future<void> _pickLogo() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final logoUrl = await ImagePickerService.pickCompanyLogo();
      if (logoUrl != null) {
        setState(() {
          _companyLogoUrl = logoUrl;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading logo: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _companyNameController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _deadline) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  Future<void> _saveJob(String? recruiterId) async {
    if (_formKey.currentState?.validate() ?? false) {
      final jobService = Provider.of<JobService>(context, listen: false);

      if (recruiterId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to post a job'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      // Format salary as string with currency
      String? formattedSalary;
      if (_salaryController.text.isNotEmpty) {
        formattedSalary = '$_selectedCurrency ${_salaryController.text}';
      }

      // Parse salary as double for the model if needed
      double? salary;
      if (_salaryController.text.isNotEmpty) {
        try {
          // Try to parse as a number (remove commas first)
          salary = double.parse(_salaryController.text.replaceAll(',', ''));
        } catch (e) {
          // If text is not a valid number (like "Negotiable")
          // Try to see if we can still create the job with textual salary
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('For now, please enter a numeric salary value'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }

      // Parse skills from comma-separated list
      List<String>? skills;
      if (_skillsController.text.isNotEmpty) {
        skills = _skillsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }

      // Create or update job model
      final job = widget.job != null
          ? widget.job!.copyWith(
        jobTitle: _titleController.text,
        companyName: _companyNameController.text,
        location: _locationController.text,
        description: _descriptionController.text,
        requirements: _requirementsController.text,
        jobType: _jobType,
        deadline: _deadline,
        salary: salary, // Pass as double or null
        companyLogo: _companyLogoUrl,
        skills: skills,
      )
          : JobModel(
        recruiterId: recruiterId,
        jobTitle: _titleController.text,
        companyName: _companyNameController.text,
        location: _locationController.text,
        description: _descriptionController.text,
        requirements: _requirementsController.text,
        jobType: _jobType,
        deadline: _deadline,
        status: 'Open',
        salary: salary, // Pass as double or null
        companyLogo: _companyLogoUrl,
        skills: skills,
        datePosted: DateTime.now(),
      );

      try {
        if (widget.job != null) {
          // Update existing job
          await jobService.updateJob(job);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Job updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }
        } else {
          // Create new job
          await jobService.createJob(job);

          // AFTER successful job creation, send notifications to relevant job seekers
          if (mounted && skills != null && skills.isNotEmpty) {
            try {
              final notificationService = Provider.of<NotificationService>(context, listen: false);

              // Find job seekers with matching skills
              final relevantJobSeekers = await _findRelevantJobSeekers(skills);

              if (relevantJobSeekers.isNotEmpty) {
                await notificationService.notifyNewJob(
                  jobSeekerIds: relevantJobSeekers,
                  jobTitle: _titleController.text,
                  companyName: _companyNameController.text,
                  jobId: null, // We don't have the job ID here, so pass null
                );
                debugPrint('Job notifications sent to ${relevantJobSeekers.length} job seekers');
              }
            } catch (e) {
              debugPrint('Failed to send job notifications: $e');
              // Don't show this error to the user since the job was created successfully
            }
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Job posted successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

// Helper method to find job seekers with matching skills
  Future<List<String>> _findRelevantJobSeekers(List<String> jobSkills) async {
    final List<String> relevantUserIds = [];

    try {
      final supabase = AppConfig().supabaseClient;

      // For each skill, find users with that skill
      for (final skill in jobSkills) {
        final response = await supabase
            .from('jobseeker_profiles')
            .select('user_id')
            .ilike('skills', '%$skill%')
            .limit(20); // Limit to a reasonable number

        if (response != null && response is List && response.isNotEmpty) {
          for (var profile in response) {
            final userId = profile['user_id'].toString();
            // Only add unique user IDs
            if (!relevantUserIds.contains(userId)) {
              relevantUserIds.add(userId);
            }
          }
        }
      }

      debugPrint('Found ${relevantUserIds.length} relevant job seekers for skills: $jobSkills');
    } catch (e) {
      debugPrint('Error finding relevant job seekers: $e');
    }

    return relevantUserIds;
  }

  Widget _buildLogoSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Company Logo',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _isUploading ? null : _pickLogo,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: _isUploading
                ? const Center(child: CircularProgressIndicator())
                : _companyLogoUrl != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _companyLogoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image,
                        size: 40, color: Colors.grey.shade600),
                    const SizedBox(height: 8),
                    const Text('Failed to load image',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate,
                    size: 40, color: Colors.grey.shade600),
                const SizedBox(height: 8),
                const Text('Tap to add logo',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
        if (_companyLogoUrl != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _companyLogoUrl = null;
                });
              },
              icon: const Icon(Icons.delete, size: 20),
              label: const Text('Remove Logo'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobService = Provider.of<JobService>(context);
    final isEditing = widget.job != null;
    final authService = Provider.of<AuthService>(context);
    final recruiterId = authService.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Job' : 'Create Job'),
      ),
      body: jobService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Job Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Job Title',
                  hintText: 'Enter job title',
                  prefixIcon: Icon(Icons.work_outline),
                ),
                validator: (value) => Validators.validateRequired(
                  value,
                  'Job title',
                ),
              ),
              const SizedBox(height: 16),

              // Company Name
              TextFormField(
                controller: _companyNameController,
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  hintText: 'Enter company name',
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) => Validators.validateRequired(
                  value,
                  'Company name',
                ),
              ),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'Enter job location (e.g., Remote, Kampala)',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (value) => Validators.validateRequired(
                  value,
                  'Location',
                ),
              ),
              const SizedBox(height: 16),

              // Company Logo Picker
              _buildLogoSelector(),

              // Salary with currency dropdown - FIX OVERFLOW
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Currency dropdown
                  Flexible(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        // Remove prefixIcon to save space
                      ),
                      items: _currencies
                          .map((currency) => DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCurrency = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Salary amount
                  Flexible(
                    flex: 3,
                    child: TextFormField(
                      controller: _salaryController,
                      decoration: const InputDecoration(
                        labelText: 'Salary',
                        hintText: 'e.g. 500000 or Negotiable',
                        // Remove dollar sign icon
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Skills input
              TextFormField(
                controller: _skillsController,
                decoration: const InputDecoration(
                  labelText: 'Skills Required',
                  hintText: 'Enter skills separated by commas (e.g. JavaScript, React, Node.js)',
                  prefixIcon: Icon(Icons.psychology_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Job Type Dropdown
              DropdownButtonFormField<String>(
                value: _jobType,
                decoration: const InputDecoration(
                  labelText: 'Job Type',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _jobTypes
                    .map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _jobType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Deadline Date Picker
              GestureDetector(
                onTap: _selectDeadline,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Application Deadline',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('MMM dd, yyyy').format(_deadline),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Job Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Job Description',
                  hintText: 'Enter detailed job description',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 5,
                validator: (value) => Validators.validateRequired(
                  value,
                  'Job description',
                ),
              ),
              const SizedBox(height: 16),

              // Job Requirements
              TextFormField(
                controller: _requirementsController,
                decoration: const InputDecoration(
                  labelText: 'Job Requirements',
                  hintText: 'Enter job requirements (education, experience, etc.)',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.list_alt_outlined),
                ),
                maxLines: 5,
                validator: (value) => Validators.validateRequired(
                  value,
                  'Job requirements',
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: jobService.isLoading ? null : () => _saveJob(recruiterId),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  isEditing ? 'Update Job' : 'Post Job',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}