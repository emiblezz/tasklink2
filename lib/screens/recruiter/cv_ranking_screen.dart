import 'package:flutter/material.dart';
import 'package:tasklink2/models/job_model.dart';
import 'package:tasklink2/models/resume_match_result_model.dart';
import 'package:tasklink2/services/ranking_service.dart';
import 'package:tasklink2/services/resume_match_service.dart';
import 'package:tasklink2/config/app_config.dart';
import 'package:tasklink2/services/ai_services.dart';
import 'package:tasklink2/services/resume_service.dart';

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

  final ResumeMatchService _resumeMatchService = ResumeMatchService();

  final ResumeService _resumeService = ResumeService(
    supabaseClient: AppConfig().supabaseClient,
    aiService: AIService(baseUrl: AppConfig.backendUrl),
  );

  late TabController _tabController;

  bool _isLoading = false;
  List<Map<String, dynamic>> _rankedApplications = [];
  String? _errorMessage;

  ResumeMatchResultModel? _personalMatchResult;
  bool _isMatchingPersonalResume = false;
  String? _personalResumeText;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentUserId = AppConfig().supabaseClient.auth.currentUser?.id;
    _fetchRankedApplications();
    _loadExistingMatchResult();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          _errorMessage = "No resume found. Please upload your resume first.";
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

  Future<void> _fetchRankedApplications() async {
    if (_currentUserId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // First check if we have match results in the database
      final matchResults = await _resumeMatchService.getMatchResultsForJob(
          widget.job.id!.toString()
      );

      if (matchResults.isNotEmpty) {
        // We have match results, convert them to the format expected by the UI
        final List<Map<String, dynamic>> rankedApps = [];

        for (final result in matchResults) {
          try {
            final appData = await AppConfig().supabaseClient
                .from('applications')
                .select('*, applicant:profiles(*)')
                .eq('applicant_id', result.applicantId)
                .eq('job_id', widget.job.id)
                .single();

            // Extract matched and missing skills from word matches
            final List<String> matchedSkills = result.wordMatches
                .where((match) => match.score > 0.7)
                .map((match) => match.resumeWord)
                .toSet()
                .toList();

            final List<String> missingSkills = result.wordMatches
                .where((match) => match.score < 0.4)
                .map((match) => match.jobWord)
                .toSet()
                .toList();

            rankedApps.add({
              'application': appData,
              'score': result.similarityScore,
              'matching_skills': matchedSkills,
              'missing_skills': missingSkills,
              'decision': result.decision,
              'improvement_suggestions': result.improvementSuggestions,
            });
          } catch (e) {
            debugPrint('Error loading application data for ${result.applicantId}: $e');
            // Continue with next result
          }
        }

        // Sort by score in descending order
        rankedApps.sort((a, b) => (b['score'] as num).compareTo(a['score'] as num));

        setState(() {
          _rankedApplications = rankedApps;
          _isLoading = false;
        });
      } else {
        // No stored results, use traditional ranking method
        await _rankApplications();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching ranking results: $e';
      });
    }
  }

  Future<void> _rankApplications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rankedApplications = await _rankingService.rankApplications(
        widget.job.id!.toString(),
        widget.job.description!,
      );

      setState(() {
        _rankedApplications = rankedApplications;
        _rankedApplications = rankedApplications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error ranking applications: $e';
      });
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
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _rankApplications,
              child: const Text('Try Again'),
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

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${application['applicant']['full_name']}',
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
                        'Score: ${(score * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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
                const SizedBox(height: 12),
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

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        // Navigate to applicant profile
                      },
                      child: const Text('View Profile'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to application details
                      },
                      child: const Text('View Application'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPersonalMatchTab() {
    if (_isMatchingPersonalResume) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Analyzing your resume match...'),
          ],
        ),
      );
    }

    if (_personalResumeText == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.note_alt_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No resume found.'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Navigate to upload resume screen
              },
              child: const Text('Upload Resume'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Job details card
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.job.jobTitle ?? 'Job Title',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.job.jobType ?? 'Company',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Location: ${widget.job.jobType ?? 'Not specified'}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Salary: ${widget.job.jobType ?? 'Not specified'}',
                  ),
                ],
              ),
            ),
          ),

          // Match button
          ElevatedButton.icon(
            onPressed: _fetchPersonalResumeAndMatch,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Match'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
          const SizedBox(height: 24),

          // Error Message
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade800),
              ),
            ),

          // Results
          if (_personalMatchResult != null) ...[
            const Divider(height: 32),
            const Text(
              'Match Analysis',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Match Date
            Text(
              'Analyzed on: ${_formatDate(_personalMatchResult!.matchDate)}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),

            // Similarity Score
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _personalMatchResult!.decision == 'Match'
                    ? Colors.green.shade100
                    : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Match Score: ${(_personalMatchResult!.similarityScore * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _personalMatchResult!.decision == 'Match'
                          ? Colors.green.shade800
                          : Colors.orange.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Decision: ${_personalMatchResult!.decision}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _personalMatchResult!.decision == 'Match'
                          ? Colors.green.shade800
                          : Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Improvement Suggestions
            if (_personalMatchResult!.improvementSuggestions != null) ...[
              const Text(
                'Personalized Feedback',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _personalMatchResult!.improvementSuggestions!,
                      style: TextStyle(
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Word Matches
            const Text(
              'Key Word Matches',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Word Matches Table
            if (_personalMatchResult!.wordMatches.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Resume Word')),
                    DataColumn(label: Text('Job Word')),
                    DataColumn(label: Text('Score')),
                  ],
                  rows: _personalMatchResult!.wordMatches
                      .take(10) // Show top 10 matches
                      .map((match) => DataRow(
                    cells: [
                      DataCell(Text(match.resumeWord)),
                      DataCell(Text(match.jobWord)),
                      DataCell(Text(
                        (match.score * 100).toStringAsFixed(1) + '%',
                        style: TextStyle(
                          color: match.score > 0.7
                              ? Colors.green.shade800
                              : match.score > 0.5
                              ? Colors.orange.shade800
                              : Colors.red.shade800,
                        ),
                      )),
                    ],
                  ))
                      .toList(),
                ),
              ),

            // Note about full matches
            if (_personalMatchResult!.wordMatches.length > 10)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Showing top 10 of ${_personalMatchResult!.wordMatches.length} matches.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to resume edit screen
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Improve Resume'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Apply for job if not already applied
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Apply'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _personalMatchResult!.decision == 'Match'
                        ? Colors.green
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecruiterAnalyticsTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Calculate analytics from ranked applications
    final totalApplications = _rankedApplications.length;
    final matchedApplications = _rankedApplications
        .where((app) => (app['decision'] == 'Match' || (app['score'] as double) >= 0.75))
        .length;
    final notMatchedApplications = totalApplications - matchedApplications;

    // Calculate average score
    final double avgScore = totalApplications > 0
        ? _rankedApplications.fold(0.0, (sum, app) => sum + (app['score'] as double)) / totalApplications
        : 0.0;

    // Get top skills across all applicants
    final Map<String, int> skillFrequency = {};
    for (final app in _rankedApplications) {
      final matchingSkills = app['matching_skills'] as List<dynamic>?;
      if (matchingSkills != null) {
        for (final skill in matchingSkills) {
          skillFrequency[skill.toString()] = (skillFrequency[skill.toString()] ?? 0) + 1;
        }
      }
    }

    // Get most common missing skills
    final Map<String, int> missingSkillFrequency = {};
    for (final app in _rankedApplications) {
      final missingSkills = app['missing_skills'] as List<dynamic>?;
      if (missingSkills != null) {
        for (final skill in missingSkills) {
          missingSkillFrequency[skill.toString()] = (missingSkillFrequency[skill.toString()] ?? 0) + 1;
        }
      }
    }

    // Sort skills by frequency
    final topSkills = skillFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topMissingSkills = missingSkillFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Job Title and Stats
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.job.jobTitle ?? 'Job Title',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.job.jobTitle ?? 'Company',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(
                        'Total',
                        totalApplications.toString(),
                        Icons.group,
                        Colors.blue,
                      ),
                      _buildStatItem(
                        'Matched',
                        matchedApplications.toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                      _buildStatItem(
                        'Not Matched',
                        notMatchedApplications.toString(),
                        Icons.cancel,
                        Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Average Score
                  LinearProgressIndicator(
                    value: avgScore,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor(avgScore)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Average Match Score: ${(avgScore * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Top Skills Among Applicants
          if (topSkills.isNotEmpty) ...[
            const Text(
              'Top Skills Among Applicants',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < topSkills.length && i < 5; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                topSkills[i].key,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              '${topSkills[i].value} applicants',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Most Common Missing Skills
          if (topMissingSkills.isNotEmpty) ...[
            const Text(
              'Most Common Missing Skills',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < topMissingSkills.length && i < 5; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                topMissingSkills[i].key,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              'Missing in ${topMissingSkills[i].value} applicants',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Skill Match Distribution
          const Text(
            'Match Score Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDistributionItem(
                    'Excellent (75-100%)',
                    _rankedApplications.where((app) => (app['score'] as double) >= 0.75).length,
                    totalApplications,
                    Colors.green,
                  ),
                  const SizedBox(height: 8),
                  _buildDistributionItem(
                    'Good (60-75%)',
                    _rankedApplications.where((app) => (app['score'] as double) >= 0.6 && (app['score'] as double) < 0.75).length,
                    totalApplications,
                    Colors.blue,
                  ),
                  const SizedBox(height: 8),
                  _buildDistributionItem(
                    'Fair (40-60%)',
                    _rankedApplications.where((app) => (app['score'] as double) >= 0.4 && (app['score'] as double) < 0.6).length,
                    totalApplications,
                    Colors.orange,
                  ),
                  const SizedBox(height: 8),
                  _buildDistributionItem(
                    'Poor (0-40%)',
                    _rankedApplications.where((app) => (app['score'] as double) < 0.4).length,
                    totalApplications,
                    Colors.red,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildDistributionItem(String label, int count, int total, Color color) {
    final double percentage = total > 0 ? count / total : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('$count (${(percentage * 100).toStringAsFixed(1)}%)'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.blue;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}