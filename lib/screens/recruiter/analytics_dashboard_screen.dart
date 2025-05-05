import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasklink2/services/analytics_service.dart';
import 'package:tasklink2/services/auth_service.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _jobMetrics = {};
  Map<String, dynamic> _conversionMetrics = {};
  Map<String, dynamic> _rankingMetrics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final analyticsService = Provider.of<AnalyticsService>(context, listen: false);

      if (authService.currentUser != null) {
        final userId = authService.currentUser!.id;

        // Load all analytics data in parallel
        final results = await Future.wait([
          analyticsService.getJobAnalytics(userId),
          analyticsService.getApplicationConversionAnalytics(userId),
          analyticsService.getRankingAnalytics(userId),
        ]);

        setState(() {
          _jobMetrics = results[0];
          _conversionMetrics = results[1];
          _rankingMetrics = results[2];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading analytics: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
            tooltip: 'Refresh Data',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Conversions'),
            Tab(text: 'AI Ranking'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildConversionsTab(),
          _buildRankingTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_jobMetrics.isEmpty || _jobMetrics.containsKey('error')) {
      return Center(
        child: Text(
          _jobMetrics.containsKey('error')
              ? _jobMetrics['error']
              : 'No analytics data available',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    final jobMetrics = _jobMetrics['jobMetrics'];
    final applicationMetrics = _jobMetrics['applicationMetrics'];
    final timeMetrics = _jobMetrics['timeMetrics'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Job Metrics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildMetricGrid([
            {
              'title': 'Total Jobs',
              'value': jobMetrics['totalJobs'].toString(),
              'icon': Icons.work,
              'color': Colors.blue,
            },
            {
              'title': 'Active Jobs',
              'value': jobMetrics['activeJobs'].toString(),
              'icon': Icons.work_outline,
              'color': Colors.green,
            },
            {
              'title': 'Closed Jobs',
              'value': jobMetrics['closedJobs'].toString(),
              'icon': Icons.check_circle,
              'color': Colors.orange,
            },
            {
              'title': 'Last 30 Days',
              'value': jobMetrics['lastMonthJobs'].toString(),
              'icon': Icons.date_range,
              'color': Colors.purple,
            },
          ]),
          const SizedBox(height: 24),
          Text(
            'Application Metrics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildMetricGrid([
            {
              'title': 'Total Applications',
              'value': applicationMetrics['totalApplications'].toString(),
              'icon': Icons.people,
              'color': Colors.indigo,
            },
            {
              'title': 'Pending',
              'value': applicationMetrics['pendingApplications'].toString(),
              'icon': Icons.hourglass_empty,
              'color': Colors.amber,
            },
            {
              'title': 'Selected',
              'value': applicationMetrics['selectedApplications'].toString(),
              'icon': Icons.check_circle,
              'color': Colors.green,
            },
            {
              'title': 'Rejected',
              'value': applicationMetrics['rejectedApplications'].toString(),
              'icon': Icons.cancel,
              'color': Colors.red,
            },
          ]),
          const SizedBox(height: 24),
          Text(
            'Performance Metrics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildMetricGrid([
            {
              'title': 'Applications per Job',
              'value': applicationMetrics['applicationsPerJob'],
              'icon': Icons.people,
              'color': Colors.teal,
            },
            {
              'title': 'Selection Rate',
              'value': applicationMetrics['selectionRate'],
              'icon': Icons.thumb_up,
              'color': Colors.blue,
            },
            {
              'title': 'Avg. Time to Fill',
              'value': timeMetrics['avgTimeToFill'],
              'icon': Icons.timer,
              'color': Colors.deepOrange,
            },
            {
              'title': 'AI Rank Accuracy',
              'value': _rankingMetrics.containsKey('rankingAvailable') && _rankingMetrics['rankingAvailable']
                  ? _rankingMetrics['accuracyRate']
                  : 'N/A',
              'icon': Icons.auto_awesome,
              'color': Colors.purple,
            },
          ]),
        ],
      ),
    );
  }

  Widget _buildConversionsTab() {
    if (_conversionMetrics.isEmpty || _conversionMetrics.containsKey('error')) {
      return Center(
        child: Text(
          _conversionMetrics.containsKey('error')
              ? _conversionMetrics['error']
              : 'No conversion data available',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    final overallConversion = _conversionMetrics['overallConversion'];
    final highPerformingJobs = _conversionMetrics['highPerformingJobs'];
    final lowPerformingJobs = _conversionMetrics['lowPerformingJobs'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConversionFunnel(overallConversion),
          const SizedBox(height: 24),
          Text(
            'High Performing Jobs',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          highPerformingJobs.isEmpty
              ? const Text('No data available yet')
              : Column(
            children: List.generate(
              highPerformingJobs.length,
                  (index) => _buildJobConversionItem(
                jobId: highPerformingJobs[index]['jobId'],
                conversionRate: highPerformingJobs[index]['conversionRate'],
                applicationsCount: highPerformingJobs[index]['applicationsCount'],
                selectedCount: highPerformingJobs[index]['selectedCount'],
                isHighPerforming: true,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Low Performing Jobs',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          lowPerformingJobs.isEmpty
              ? const Text('No data available yet')
              : Column(
            children: List.generate(
              lowPerformingJobs.length,
                  (index) => _buildJobConversionItem(
                jobId: lowPerformingJobs[index]['jobId'],
                conversionRate: lowPerformingJobs[index]['conversionRate'],
                applicationsCount: lowPerformingJobs[index]['applicationsCount'],
                selectedCount: lowPerformingJobs[index]['selectedCount'],
                isHighPerforming: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingTab() {
    if (!_rankingMetrics.containsKey('rankingAvailable') || !_rankingMetrics['rankingAvailable']) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'AI Ranking Analytics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _rankingMetrics.containsKey('message')
                  ? _rankingMetrics['message']
                  : 'No ranking data available yet',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to the CV ranking screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Use the CV Ranking feature to generate ranking data'),
                  ),
                );
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Start Ranking CVs'),
            ),
          ],
        ),
      );
    }

    final selectionRates = _rankingMetrics['selectionRatesByScore'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Ranking Effectiveness',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAIMetricCard(
                          title: 'Accuracy Rate',
                          value: _rankingMetrics['accuracyRate'],
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildAIMetricCard(
                          title: 'Ranked Applications',
                          value: _rankingMetrics['totalRankedApplications'].toString(),
                          icon: Icons.people,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Selection Rates by Score',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildScoreConversionCard(
            title: 'High Score (80-100%)',
            total: selectionRates['highScore']['total'],
            selected: selectionRates['highScore']['selected'],
            rate: selectionRates['highScore']['rate'],
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildScoreConversionCard(
            title: 'Medium Score (60-79%)',
            total: selectionRates['mediumScore']['total'],
            selected: selectionRates['mediumScore']['selected'],
            rate: selectionRates['mediumScore']['rate'],
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildScoreConversionCard(
            title: 'Low Score (0-59%)',
            total: selectionRates['lowScore']['total'],
            selected: selectionRates['lowScore']['selected'],
            rate: selectionRates['lowScore']['rate'],
            color: Colors.red,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Insights',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildInsightItem(
                    'AI ranking shows ${selectionRates['highScore']['rate']} selection rate for high-scored candidates.',
                    Icons.insights,
                    Colors.purple,
                  ),
                  const SizedBox(height: 8),
                  _buildInsightItem(
                    'Your overall AI recommendation accuracy is ${_rankingMetrics['accuracyRate']}.',
                    Icons.auto_awesome,
                    Colors.blue,
                  ),
                  if (selectionRates['lowScore']['selected'] > 0)
                    const SizedBox(height: 8),
                  if (selectionRates['lowScore']['selected'] > 0)
                    _buildInsightItem(
                      'You selected ${selectionRates['lowScore']['selected']} candidates that received low scores.',
                      Icons.warning,
                      Colors.orange,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricGrid(List<Map<String, dynamic>> metrics) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 1.5,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  metric['icon'],
                  color: metric['color'],
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  metric['title'],
                  style: Theme.of(context).textTheme.titleSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  metric['value'],
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: metric['color'],
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConversionFunnel(Map<String, dynamic> conversionData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Application Funnel',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildFunnelStep(
              'Total Applications',
              conversionData['totalApplications'].toString(),
              Colors.blue,
              1.0,
            ),
            const SizedBox(height: 8),
            _buildFunnelStep(
              'Selected Candidates',
              conversionData['selectedApplications'].toString(),
              Colors.green,
              conversionData['totalApplications'] > 0
                  ? conversionData['selectedApplications'] / conversionData['totalApplications']
                  : 0.0,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAIMetricCard(
                    title: 'Overall Conversion',
                    value: conversionData['conversionRate'],
                    icon: Icons.assessment,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAIMetricCard(
                    title: 'Pending to Selected',
                    value: conversionData['pendingToSelectedRate'],
                    icon: Icons.trending_up,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFunnelStep(String title, String value, Color color, double widthFactor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FractionallySizedBox(
          widthFactor: widthFactor,
          child: Container(
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJobConversionItem({
    required int jobId,
    required double conversionRate,
    required int applicationsCount,
    required int selectedCount,
    required bool isHighPerforming,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isHighPerforming ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              child: Icon(
                isHighPerforming ? Icons.trending_up : Icons.trending_down,
                color: isHighPerforming ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Job #$jobId',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$selectedCount selected out of $applicationsCount applications',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isHighPerforming ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${conversionRate.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: isHighPerforming ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreConversionCard({
    required String title,
    required int total,
    required int selected,
    required String rate,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('$selected selected out of $total applications'),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                rate,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(String text, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text),
        ),
      ],
    );
  }
}