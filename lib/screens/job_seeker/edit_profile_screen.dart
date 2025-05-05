import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasklink2/models/jobseeker_profile_model.dart';
import 'package:tasklink2/screens/auth/login_screen.dart';
import 'package:tasklink2/services/auth_service.dart';
import 'package:tasklink2/services/profile_service.dart';
import 'package:tasklink2/utils/validators.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _skillsController = TextEditingController();
  final _experienceController = TextEditingController();
  final _educationController = TextEditingController();
  final _linkedinController = TextEditingController();
  String? _cvUrl;
  String? _cvFileName;
  String? _cvOriginalName; // Added to store original file name
  bool _isUploading = false;
  bool _isFallbackMode = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _skillsController.dispose();
    _experienceController.dispose();
    _educationController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profileService = Provider.of<ProfileService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    if (authService.currentUser != null) {
      await profileService.fetchProfile(authService.currentUser!.id);

      if (profileService.profile != null) {
        setState(() {
          _skillsController.text = profileService.profile!.skills ?? '';
          _experienceController.text = profileService.profile!.experience ?? '';
          _educationController.text = profileService.profile!.education ?? '';
          _linkedinController.text = profileService.profile!.linkedinProfile ?? '';
          _cvUrl = profileService.profile!.cv;

          // Extract file name from URL
          if (_cvUrl != null && _cvUrl!.isNotEmpty) {
            // Check if this is a fallback CV
            _isFallbackMode = _cvUrl!.contains('#fallback');

            // Clean the URL for display
            String cleanUrl = _cvUrl!;
            if (cleanUrl.contains('#')) {
              cleanUrl = cleanUrl.substring(0, cleanUrl.indexOf('#'));
            }

            final parts = cleanUrl.split('/');
            _cvFileName = parts.last;

            // Extract original file name from timestamp_originalname format
            if (_cvFileName!.contains('_')) {
              final nameParts = _cvFileName!.split('_');
              if (nameParts.length > 1 && nameParts[0].isNotEmpty) {
                // Check if first part looks like a timestamp (all digits)
                final firstPart = nameParts[0];
                // Fixed this to avoid String to int conversion
                if (RegExp(r'^\d+$').hasMatch(firstPart)) {
                  // Remove the timestamp part
                  _cvOriginalName = nameParts.sublist(1).join('_');
                }
              }
            }
          }
        });
      }
    }
  }

  Future<void> _uploadCV() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final profileService = Provider.of<ProfileService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      if (authService.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to upload a CV'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final userId = authService.currentUser!.id;

      // Use the file picker to upload CV
      final newCvUrl = await profileService.pickAndUploadCV(userId);

      if (newCvUrl != null) {
        setState(() {
          _cvUrl = newCvUrl;

          // Check if it was a fallback upload
          _isFallbackMode = newCvUrl.contains('#fallback');

          // Clean the URL for display
          String cleanUrl = newCvUrl;
          if (cleanUrl.contains('#')) {
            cleanUrl = cleanUrl.substring(0, cleanUrl.indexOf('#'));
          }

          final parts = cleanUrl.split('/');
          _cvFileName = parts.isNotEmpty ? parts.last : null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFallbackMode
                ? 'CV uploaded successfully (fallback mode)'
                : 'CV uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (profileService.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(profileService.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading CV: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      final profileService = Provider.of<ProfileService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      if (authService.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to save your profile'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final userId = authService.currentUser!.id;

      final profile = JobSeekerProfileModel(
        userId: userId,
        cv: _cvUrl,
        skills: _skillsController.text,
        experience: _experienceController.text,
        education: _educationController.text,
        linkedinProfile: _linkedinController.text,
      );

      final result = await profileService.saveProfile(profile);

      if (mounted) {
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(profileService.errorMessage ?? 'Failed to save profile'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _logout() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      // Perform logout
      await authService.logout();

      if (!mounted) return;

      // Navigate to login screen and clear the navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileService = Provider.of<ProfileService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          // Logout button in app bar
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: profileService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // CV Upload
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resume/CV',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_cvFileName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.description),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  // Display original name if available, otherwise file name
                                  _cvOriginalName ?? _cvFileName!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (_isFallbackMode)
                                  const Text(
                                    '(Using fallback mode)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    onPressed: _isUploading ? null : _uploadCV,
                    icon: const Icon(Icons.upload_file),
                    label: _isUploading
                        ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Uploading...'),
                      ],
                    )
                        : Text(_cvFileName == null
                        ? 'Upload CV'
                        : 'Change CV'),
                  ),

                  if (_cvFileName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        // Show more informative file info
                        _cvOriginalName != null
                            ? 'File: $_cvOriginalName'
                            : 'File: $_cvFileName',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                    ),

                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Upload PDF, DOC, or DOCX files',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Form inside ListView
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Skills
                TextFormField(
                  controller: _skillsController,
                  decoration: const InputDecoration(
                    labelText: 'Skills',
                    hintText: 'Enter your skills (e.g., JavaScript, Project Management)',
                    prefixIcon: Icon(Icons.assessment_outlined),
                  ),
                  validator: (value) => Validators.validateRequired(
                    value,
                    'Skills',
                  ),
                ),
                const SizedBox(height: 16),

                // Experience
                TextFormField(
                  controller: _experienceController,
                  decoration: const InputDecoration(
                    labelText: 'Work Experience',
                    hintText: 'Describe your work experience',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.work_outline),
                  ),
                  maxLines: 3,
                  validator: (value) => Validators.validateRequired(
                    value,
                    'Work experience',
                  ),
                ),
                const SizedBox(height: 16),

                // Education
                TextFormField(
                  controller: _educationController,
                  decoration: const InputDecoration(
                    labelText: 'Education',
                    hintText: 'Enter your educational background',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  maxLines: 3,
                  validator: (value) => Validators.validateRequired(
                    value,
                    'Education',
                  ),
                ),
                const SizedBox(height: 16),

                // LinkedIn
                TextFormField(
                  controller: _linkedinController,
                  decoration: const InputDecoration(
                    labelText: 'LinkedIn Profile',
                    hintText: 'Enter your LinkedIn profile URL',
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
                const SizedBox(height: 24),

                // Save Button
                ElevatedButton(
                  onPressed: profileService.isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: profileService.isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Save Profile',
                    style: TextStyle(fontSize: 16),
                  ),
                ),

                const SizedBox(height: 16),

                // Logout Button
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Log Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),

                // Extra bottom padding to ensure no overflow
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}