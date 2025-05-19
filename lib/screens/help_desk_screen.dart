import 'package:flutter/material.dart';
import 'package:tasklink2/utils/theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class HelpDeskScreen extends StatefulWidget {
  final bool isRecruiter;

  const HelpDeskScreen({Key? key, required this.isRecruiter}) : super(key: key);

  @override
  State<HelpDeskScreen> createState() => _HelpDeskScreenState();
}

class _HelpDeskScreenState extends State<HelpDeskScreen> {
  final List<Map<String, dynamic>> _faqList = [
    {
      'question': 'How do I create a profile?',
      'answer': 'To create a profile, go to the Profile tab, then tap on Edit Profile. Fill in your details and save to complete your profile setup.'
    },
    {
      'question': 'How can I reset my password?',
      'answer': 'You can reset your password by going to the Login screen and tapping on the "Forgot Password" link. Follow the instructions sent to your email.'
    },
    {
      'question': 'What happens after I apply for a job?',
      'answer': 'After applying for a job, the recruiter will review your application. You can track the status in the "Applications" tab. If there\'s interest, you\'ll be contacted for the next steps.'
    },
    {
      'question': 'How does the AI matching work?',
      'answer': 'Our AI system analyzes your skills, experience, and education against job requirements to find the best matches. The more detailed your profile, the better the matches will be.'
    },
    {
      'question': 'How can I contact support?',
      'answer': 'You can contact our support team via email at support@tasklink.com or use the Contact Support option in this Help Desk.'
    },
  ];


  final List<Map<String, dynamic>> _recruiterFaqList = [
    {
      'question': 'How do I post a job?',
      'answer': 'To post a job, go to the Jobs tab and tap on the "+" button. Fill in the job details including title, description, requirements, and deadline, then submit.'
    },
    {
      'question': 'How does CV ranking work?',
      'answer': 'CV ranking automatically evaluates applicants based on how well their qualifications match your job requirements. The system considers skills, experience, and education relevance to provide a match score.'
    },
    {
      'question': 'Can I edit a job posting after it\'s published?',
      'answer': 'Yes, you can edit a job posting after it\'s published. Navigate to the Jobs tab, find the job you want to edit, and tap on the edit icon.'
    },
    {
      'question': 'How can I contact an applicant?',
      'answer': 'You can contact an applicant by viewing their application in the Candidates tab and tapping on their email or phone number to initiate communication.'
    },
    {
      'question': 'How can I get support for my recruiter account?',
      'answer': 'You can contact our dedicated recruiter support team via email at recruiter-support@tasklink.com or use the Contact Support option in this Help Desk.'
    },
  ];

  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> faqList =
    widget.isRecruiter ? _recruiterFaqList : _faqList;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Desk'),
        // Replace AppTheme.primaryColor with Theme.of(context).colorScheme.primary
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for help...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  TabBar(
                    // Replace AppTheme.primaryColor with Theme.of(context).colorScheme.primary
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: 'FAQs'),
                      Tab(text: 'Tutorials'),
                      Tab(text: 'Contact'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // FAQs Tab
                        _buildFaqsTab(faqList),

                        // Tutorials Tab
                        _buildTutorialsTab(),

                        // Contact Tab
                        _buildContactTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqsTab(List<Map<String, dynamic>> faqList) {
    final filteredFaqs = faqList.where((faq) {
      return faq['question'].toLowerCase().contains(_searchQuery) ||
          faq['answer'].toLowerCase().contains(_searchQuery);
    }).toList();

    return filteredFaqs.isEmpty
        ? const Center(
      child: Text(
        'No FAQs match your search',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    )
        : ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredFaqs.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            title: Text(
              filteredFaqs[index]['question'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  filteredFaqs[index]['answer'],
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTutorialsTab() {
    final List<Map<String, dynamic>> tutorials = widget.isRecruiter
        ? [
      {
        'title': 'How to Post a Job',
        'description': 'Learn how to create effective job postings',
        'icon': Icons.work_outline,
      },
      {
        'title': 'Using CV Ranking',
        'description': 'Understand how to use the AI-driven CV ranking system',
        'icon': Icons.leaderboard,
      },
      {
        'title': 'Managing Applications',
        'description': 'Learn how to review and manage job applications',
        'icon': Icons.people,
      },
      {
        'title': 'Account Setup',
        'description': 'Set up your recruiter profile for best results',
        'icon': Icons.account_circle,
      },
    ]
        : [
      {
        'title': 'Creating Your Profile',
        'description': 'Learn how to create an effective profile',
        'icon': Icons.person_outline,
      },
      {
        'title': 'Uploading Your CV',
        'description': 'Tips for uploading and formatting your CV',
        'icon': Icons.description,
      },
      {
        'title': 'Applying for Jobs',
        'description': 'How to search and apply for jobs',
        'icon': Icons.work,
      },
      {
        'title': 'Tracking Applications',
        'description': 'How to track your job applications',
        'icon': Icons.inbox,
      },
    ];

    final filteredTutorials = tutorials.where((tutorial) {
      return tutorial['title'].toLowerCase().contains(_searchQuery) ||
          tutorial['description'].toLowerCase().contains(_searchQuery);
    }).toList();

    return filteredTutorials.isEmpty
        ? const Center(
      child: Text(
        'No tutorials match your search',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    )
        : ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredTutorials.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: Icon(
              filteredTutorials[index]['icon'],
              // Replace AppTheme.primaryColor with Theme.of(context).colorScheme.primary
              color: Theme.of(context).colorScheme.primary,
              size: 36,
            ),
            title: Text(
              filteredTutorials[index]['title'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(filteredTutorials[index]['description']),
            // Replace AppTheme.accentColor with Theme.of(context).colorScheme.secondary
            trailing: Icon(Icons.play_circle_filled, color: Theme.of(context).colorScheme.secondary),
            onTap: () {
              // Navigate to tutorial video or page
              _showTutorial(context, filteredTutorials[index]['title']);
            },
          ),
        );
      },
    );
  }

  void _showTutorial(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tutorial: $title'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.construction,
              size: 48,
              color: Colors.amber,
            ),
            SizedBox(height: 16),
            Text(
              'This tutorial is coming soon!',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'We\'re currently working on creating high-quality tutorial videos for all features.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Support',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildContactMethod(
              icon: Icons.email,
              title: 'Email Support',
              description: widget.isRecruiter
                  ? 'recruiter-support@tasklink.com'
                  : 'support@tasklink.com',
              onTap: () => _launchEmail(widget.isRecruiter
                  ? 'recruiter-support@tasklink.com'
                  : 'support@tasklink.com'),
            ),
            const SizedBox(height: 16),
            _buildContactMethod(
              icon: Icons.phone,
              title: 'Phone Support',
              description: '+256 780 245 409',
              onTap: () => _launchPhone('+256780245409'),
            ),
            const SizedBox(height: 16),
            _buildContactMethod(
              icon: Icons.chat_bubble_outline,
              title: 'Live Chat',
              description: 'Chat with a support agent',
              onTap: () => _showLiveChatDialog(context),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            const Text(
              'Submit Feedback',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Share your thoughts or report an issue...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Thank you for your feedback!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      child: const Text(
                        'Submit Feedback',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactMethod({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        // Replace AppTheme.primaryColor with Theme.of(context).colorScheme.primary
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Support Request - TaskLink App',
      },
    );

    try {
      // First attempt: Try to launch directly with explicit external application mode
      if (await canLaunchUrl(emailUri)) {
        final launched = await launchUrl(
          emailUri,
          mode: LaunchMode.externalApplication,
        );

        if (!launched) {
          // If direct launch failed, show clipboard option
          _showEmailFallbackDialog(email);
        }
      } else {
        // If canLaunchUrl returns false, show clipboard option
        _showEmailFallbackDialog(email);
      }
    } catch (e) {
      debugPrint('Error launching email: $e');
      // Show clipboard dialog as fallback
      _showEmailFallbackDialog(email);
    }
  }

// Add this helper method to provide a clipboard fallback
  void _showEmailFallbackDialog(String email) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Email App Not Found'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Could not find an email app on your device. Would you like to copy the email address to your clipboard?'
              ),
              const SizedBox(height: 12),
              Text(
                email,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: email));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Email address copied to clipboard'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Copy Email'),
            ),
          ],
        );
      },
    );
  }

  void _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch phone app. Please call $phoneNumber directly.'),
            backgroundColor: Colors.white,
          ),
        );
      }
    }
  }

  void _showLiveChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Live Chat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat,
              size: 48,
              // Replace AppTheme.primaryColor with Theme.of(context).colorScheme.primary
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Live chat support is coming soon!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'In the meantime, please contact us via email or phone for assistance.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}