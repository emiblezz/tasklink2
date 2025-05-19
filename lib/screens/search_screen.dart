import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tasklink2/models/job_search_model.dart';
import 'package:tasklink2/services/job_service.dart';

class AdvancedSearchScreen extends StatefulWidget {
  final JobSearchFilters? initialFilters;

  const AdvancedSearchScreen({
    Key? key,
    this.initialFilters,
  }) : super(key: key);

  @override
  _AdvancedSearchScreenState createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  // Text controllers
  late final TextEditingController _searchController;
  late final TextEditingController _locationController;
  late final TextEditingController _minSalaryController;
  late final TextEditingController _maxSalaryController;

  // State variables
  List<String> _selectedJobTypes = [];
  double? _minSalary;
  double? _maxSalary;
  List<String> _selectedSkills = [];
  bool _isRemote = false;

  // Common job types
  final List<String> _jobTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Freelance',
    'Internship',
    'Temporary'
  ];

  // Common skills that might be interesting to filter by
  final List<String> _commonSkills = [
    'Programming',
    'JavaScript',
    'Python',
    'SQL',
    'Marketing',
    'Sales',
    'Design',
    'Customer Service',
    'Management',
    'Finance',
    'Accounting',
    'Communication',
    'Project Management',
    'Research',
    'Teaching',
    'Writing',
    'Analysis',
    'IT',
    'Web Development',
    'Mobile Development',
    'UI/UX',
    'HR',
    'Admin',
    'Legal',
    'Engineering',
    'Healthcare',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize with any existing filters
    final filters = widget.initialFilters;

    // Initialize text controllers
    _searchController = TextEditingController(text: filters?.query ?? '');
    _locationController = TextEditingController(text: filters?.location ?? '');
    _minSalaryController = TextEditingController(
        text: filters?.minSalary?.toString() ?? ''
    );
    _maxSalaryController = TextEditingController(
        text: filters?.maxSalary?.toString() ?? ''
    );

    // Initialize state variables
    _selectedJobTypes = filters?.jobTypes?.toList() ?? [];
    _minSalary = filters?.minSalary;
    _maxSalary = filters?.maxSalary;
    _selectedSkills = filters?.skills?.toList() ?? [];
    _isRemote = filters?.isRemote ?? false;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    _minSalaryController.dispose();
    _maxSalaryController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _locationController.clear();
      _minSalaryController.clear();
      _maxSalaryController.clear();
      _selectedJobTypes = [];
      _minSalary = null;
      _maxSalary = null;
      _selectedSkills = [];
      _isRemote = false;
    });
  }

  bool _hasActiveFilters() {
    return _searchController.text.isNotEmpty ||
        _locationController.text.isNotEmpty ||
        _selectedJobTypes.isNotEmpty ||
        _minSalary != null ||
        _maxSalary != null ||
        _selectedSkills.isNotEmpty ||
        _isRemote;
  }

  void _applyFilters() {
    final JobSearchFilters filters = JobSearchFilters(
      query: _searchController.text.isEmpty ? null : _searchController.text,
      location: _locationController.text.isEmpty ? null : _locationController.text,
      jobTypes: _selectedJobTypes.isEmpty ? null : _selectedJobTypes,
      minSalary: _minSalary,
      maxSalary: _maxSalary,
      skills: _selectedSkills.isEmpty ? null : _selectedSkills,
      isRemote: _isRemote ? true : null,
    );

    Navigator.pop(context, filters);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Job Search'),
        actions: [
          if (_hasActiveFilters())
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear All', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Main content with filters
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Keyword search
                  const Text(
                    'Keywords',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Job title, company, or keywords',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Location
                  const Text(
                    'Location',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      hintText: 'City, region, or country',
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Remote work only'),
                    value: _isRemote,
                    onChanged: (value) {
                      setState(() {
                        _isRemote = value;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                  const Divider(),

                  // Job Type
                  const Text(
                    'Job Type',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _jobTypes.map((type) => FilterChip(
                      label: Text(type),
                      selected: _selectedJobTypes.contains(type),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedJobTypes.add(type);
                          } else {
                            _selectedJobTypes.remove(type);
                          }
                        });
                      },
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),

                  // Salary Range
                  const Text(
                    'Salary Range',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minSalaryController,
                          decoration: InputDecoration(
                            labelText: 'Min Salary',
                            hintText: '500000',
                            helperText: 'e.g. 500000',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixText: 'UGX ',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              setState(() {
                                _minSalary = double.tryParse(value);
                                print('Min salary set to: $_minSalary');
                              });
                            } else {
                              setState(() {
                                _minSalary = null;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _maxSalaryController,
                          decoration: InputDecoration(
                            labelText: 'Max Salary',
                            hintText: '2000000',
                            helperText: 'e.g. 2000000',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixText: 'UGX ',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              setState(() {
                                _maxSalary = double.tryParse(value);
                                print('Max salary set to: $_maxSalary');
                              });
                            } else {
                              setState(() {
                                _maxSalary = null;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),

                  // Skills
                  const Text(
                    'Skills',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _commonSkills.map((skill) => FilterChip(
                      label: Text(skill),
                      selected: _selectedSkills.contains(skill),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedSkills.add(skill);
                          } else {
                            _selectedSkills.remove(skill);
                          }
                        });
                      },
                    )).toList(),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Bottom action bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Show number of active filters
                if (_hasActiveFilters()) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_countActiveFilters()} active filter${_countActiveFilters() != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],

                // Apply button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _hasActiveFilters() ? _applyFilters : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _countActiveFilters() {
    int count = 0;
    if (_searchController.text.isNotEmpty) count++;
    if (_locationController.text.isNotEmpty) count++;
    if (_selectedJobTypes.isNotEmpty) count++;
    if (_minSalary != null || _maxSalary != null) count++;
    if (_selectedSkills.isNotEmpty) count++;
    if (_isRemote) count++;
    return count;
  }
}