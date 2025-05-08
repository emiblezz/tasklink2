import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasklink2/models/job_model.dart';
import 'package:tasklink2/screens/job_detail_screen.dart';
import 'package:tasklink2/services/search_service.dart';
import 'package:intl/intl.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, dynamic> _filters = {
    'jobType': 'All',
    'datePosted': 'Any time',
  };
  List<String> _jobTypes = ['All'];
  List<String> _suggestedSearches = [];
  bool _isFilterExpanded = false;
  bool _isInitialSearch = true;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery ?? '';
    _loadFilters();

    // If initial query is provided, search immediately
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    final searchService = Provider.of<SearchService>(context, listen: false);

    // Load job types
    final jobTypes = await searchService.getJobTypes();
    if (mounted) {
      setState(() {
        _jobTypes = jobTypes;
      });
    }

    // Load suggested searches
    final suggestions = await searchService.getSuggestedSearches();
    if (mounted) {
      setState(() {
        _suggestedSearches = suggestions;
      });
    }
  }

  void _performSearch() {
    setState(() {
      _isInitialSearch = false;
    });

    final searchService = Provider.of<SearchService>(context, listen: false);
    searchService.searchJobs(
      query: _searchController.text.trim(),
      filters: _filters,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Jobs'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by job title, skills, keywords...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                    });
                  },
                )
                    : null,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
              ),
              onSubmitted: (_) => _performSearch(),
              textInputAction: TextInputAction.search,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter section
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isFilterExpanded ? 180 : 60,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1.0,
                ),
              ),
            ),
            child: Column(
              children: [
                // Filter header
                ListTile(
                  title: Text(
                    'Filters',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      _isFilterExpanded ? Icons.expand_less : Icons.expand_more,
                    ),
                    onPressed: () {
                      setState(() {
                        _isFilterExpanded = !_isFilterExpanded;
                      });
                    },
                  ),
                ),

                // Filter content
                if (_isFilterExpanded)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Job Type filter
                        Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(
                                'Job Type:',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            Expanded(
                              child: DropdownButton<String>(
                                value: _filters['jobType'],
                                isExpanded: true,
                                items: _jobTypes.map((type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(type),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _filters['jobType'] = value;
                                    });
                                    _performSearch();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8.0),

                        // Date Posted filter
                        Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(
                                'Date Posted:',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            Expanded(
                              child: DropdownButton<String>(
                                value: _filters['datePosted'],
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(value: 'Any time', child: Text('Any time')),
                                  DropdownMenuItem(value: 'Past 24 hours', child: Text('Past 24 hours')),
                                  DropdownMenuItem(value: 'Past week', child: Text('Past week')),
                                  DropdownMenuItem(value: 'Past month', child: Text('Past month')),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _filters['datePosted'] = value;
                                    });
                                    _performSearch();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Results or suggestions
          Expanded(
            child: _isInitialSearch
                ? _buildSuggestedSearches()
                : _buildSearchResults(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _performSearch,
        child: const Icon(Icons.search),
      ),
    );
  }

  Widget _buildSuggestedSearches() {
    if (_suggestedSearches.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Suggested Searches',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _suggestedSearches.length,
            itemBuilder: (context, index) {
              final suggestion = _suggestedSearches[index];
              return ListTile(
                leading: const Icon(Icons.search),
                title: Text(suggestion),
                onTap: () {
                  setState(() {
                    _searchController.text = suggestion;
                  });
                  _performSearch();
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    final searchService = Provider.of<SearchService>(context);
    final isLoading = searchService.isLoading;
    final results = searchService.searchResults;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No jobs found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords or filters',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await searchService.refreshSearch();
      },
      child: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final job = results[index];
          return _JobSearchCard(
            job: job,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => JobDetailScreen(
                    job: job,
                    isRecruiter: false,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _JobSearchCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;

  const _JobSearchCard({
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
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company logo if available
                  if (job.companyLogo != null && job.companyLogo!.isNotEmpty)
                    Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          job.companyLogo!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.business,
                            size: 24,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.business,
                        size: 24,
                        color: Colors.grey,
                      ),
                    ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.jobTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job.companyName,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(job.status),
                    backgroundColor: job.status == 'Open'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: job.status == 'Open' ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Job type and salary
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      job.jobType,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
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
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Skills section (if available)
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
                const SizedBox(height: 8),
              ],

              // Location
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    job.location,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Description preview
              Text(
                job.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),

              // Date information
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Posted: ${job.datePosted != null ? DateFormat(
                        'MMM dd, yyyy').format(job.datePosted!) : 'N/A'}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.event,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Deadline: ${DateFormat('MMM dd, yyyy').format(
                        job.deadline)}',
                    style: TextStyle(
                      color: DateTime.now().isAfter(job.deadline.subtract(const Duration(days: 3)))
                          ? Colors.red
                          : Colors.grey[600],
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
}