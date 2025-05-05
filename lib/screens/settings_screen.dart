import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasklink2/services/auth_service.dart';
import 'package:tasklink2/utils/constants.dart';
import 'package:tasklink2/utils/theme.dart';

class SettingsScreen extends StatefulWidget {
  final bool isRecruiter;

  const SettingsScreen({Key? key, required this.isRecruiter}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        // Use Theme.of(context).colorScheme.primary instead of AppTheme.primaryColor
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildProfileSection(),
          const SizedBox(height: 20),
          _buildAppearanceSection(),
          const SizedBox(height: 20),
          _buildNotificationsSection(),
          const SizedBox(height: 20),
          _buildAccountSection(),
          const SizedBox(height: 20),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.person),
        title: const Text('Edit Profile'),
        subtitle: Text('Update your personal information'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navigate to profile editing page
          // This will be different for job seeker and recruiter
          if (widget.isRecruiter) {
            // Navigate to recruiter profile
          } else {
            // Navigate to job seeker profile
          }
        },
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Appearance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Toggle dark/light theme'),
              value: _isDarkMode,
              onChanged: (value) {
                setState(() {
                  _isDarkMode = value;
                  // Implement theme changing logic
                });
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Text Size'),
              subtitle: const Text('Adjust application text size'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Show text size options
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Enable Notifications'),
              subtitle: const Text('Receive alerts and updates'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                  // Implement notification toggle logic
                });
              },
            ),
            if (_notificationsEnabled) ...[
              const Divider(),
              ListTile(
                title: Text(widget.isRecruiter ? 'New Applications' : 'Job Matches'),
                subtitle: Text(widget.isRecruiter
                    ? 'Get notified about new applications'
                    : 'Get notified about matching jobs'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Show notification preferences
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('Email Notifications'),
                subtitle: const Text('Manage email notification settings'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Show email notification settings
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Change Password'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigate to change password screen
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy Settings'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigate to privacy settings
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          // Use logout() instead of signOut()
                          await authService.logout();
                          // Navigate to login screen
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(context, '/login');
                          }
                        },
                        child: const Text('Logout', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About TaskLink'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Show about dialog
                showAboutDialog(
                  context: context,
                  applicationName: AppConstants.appName,
                  applicationVersion: '1.0.0',
                  applicationIcon: Image.asset(
                    'assets/images/logo.png',
                    height: 50,
                    width: 50,
                  ),
                  children: const [
                    SizedBox(height: 20),
                    Text('TaskLink is an AI-driven platform connecting job seekers with recruiters for full-time job opportunities in Uganda.'),
                  ],
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Terms of Service'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigate to terms of service
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy Policy'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigate to privacy policy
              },
            ),
          ],
        ),
      ),
    );
  }
}