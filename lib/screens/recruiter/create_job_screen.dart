import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tasklink2/models/job_model.dart';
import 'package:tasklink2/services/auth_service.dart';
import 'package:tasklink2/services/job_service.dart';
import 'package:tasklink2/utils/constants.dart';
import 'package:tasklink2/utils/validators.dart';

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
  late String _jobType = 'Full-time';
  late DateTime _deadline = DateTime.now().add(const Duration(days: 30));

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
      _descriptionController.text = widget.job!.description;
      _requirementsController.text = widget.job!.requirements;
      _jobType = widget.job!.jobType;
      _deadline = widget.job!.deadline;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
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

  Future<void> _saveJob() async {
    if (_formKey.currentState?.validate() ?? false) {
      final jobService = Provider.of<JobService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      if (authService.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to post a job'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final recruiterId = authService.currentUser!.id;

      // Create or update job model
      final job = widget.job != null
          ? widget.job!.copyWith(
        jobTitle: _titleController.text,
        description: _descriptionController.text,
        requirements: _requirementsController.text,
        jobType: _jobType,
        deadline: _deadline,
      )
          : JobModel(
        recruiterId: recruiterId,
        jobTitle: _titleController.text,
        description: _descriptionController.text,
        requirements: _requirementsController.text,
        jobType: _jobType,
        deadline: _deadline,
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

  @override
  Widget build(BuildContext context) {
    final jobService = Provider.of<JobService>(context);
    final isEditing = widget.job != null;

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
                  hintText: 'Enter job requirements (skills, experience, etc.)',
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
                onPressed: jobService.isLoading ? null : _saveJob,
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