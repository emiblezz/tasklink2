import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasklink2/models/recruiter_profile_model.dart';
import 'package:tasklink2/screens/auth/login_screen.dart';
import 'package:tasklink2/services/auth_service.dart';
import 'package:tasklink2/services/recruiter_profile_service.dart';
import 'package:tasklink2/utils/validators.dart';

class EditRecruiterProfileScreen extends StatefulWidget {
  const EditRecruiterProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditRecruiterProfileScreen> createState() => _EditRecruiterProfileScreenState();
}

class _EditRecruiterProfileScreenState extends State<EditRecruiterProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _companyDescriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  final _industryController = TextEditingController();
  final _locationController = TextEditingController();
  String? _logoUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyDescriptionController.dispose();
    _websiteController.dispose();
    _industryController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profileService = Provider.of<RecruiterProfileService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    if (authService.currentUser != null) {
      await profileService.fetchProfile(authService.currentUser!.id);

      if (profileService.recruiterProfile != null) {
        setState(() {
          _companyNameController.text = profileService.recruiterProfile!.companyName ?? '';
          _companyDescriptionController.text = profileService.recruiterProfile!.companyDescription ?? '';
          _websiteController.text = profileService.recruiterProfile!.website ?? '';
          _industryController.text = profileService.recruiterProfile!.industry ?? '';
          _locationController.text = profileService.recruiterProfile!.location ?? '';
          _logoUrl = profileService.recruiterProfile!.logoUrl;
        });
      }
    }
  }

  Future<void> _pickLogo() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final profileService = Provider.of<RecruiterProfileService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      if (authService.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to upload a logo'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final userId = authService.currentUser!.id;
      final newLogoUrl = await profileService.pickAndUploadLogo(userId);

      if (newLogoUrl != null) {
        setState(() {
          _logoUrl = newLogoUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company logo uploaded successfully'),
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

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      final profileService = Provider.of<RecruiterProfileService>(context, listen: false);
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

      final profile = RecruiterProfileModel(
        userId: userId,
        companyName: _companyNameController.text,
        companyDescription: _companyDescriptionController.text,
        website: _websiteController.text,
        industry: _industryController.text,
        location: _locationController.text,
        logoUrl: _logoUrl,
      );

      final result = await profileService.saveProfile(profile);

      if (mounted) {
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Company profile saved successfully'),
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
                : _logoUrl != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _logoUrl!,
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
        if (_logoUrl != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _logoUrl = null;
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
    final profileService = Provider.of<RecruiterProfileService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Company Profile'),
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
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Company Logo Picker
              _buildLogoSelector(),

              // Company Name
              TextFormField(
                controller: _companyNameController,
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  hintText: 'Enter your company name',
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) => Validators.validateRequired(
                  value,
                  'Company name',
                ),
              ),
              const SizedBox(height: 16),

              // Industry
              TextFormField(
                controller: _industryController,
                decoration: const InputDecoration(
                  labelText: 'Industry',
                  hintText: 'Enter your industry (e.g., Technology, Healthcare)',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                validator: (value) => Validators.validateRequired(
                  value,
                  'Industry',
                ),
              ),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'Enter your company location',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (value) => Validators.validateRequired(
                  value,
                  'Location',
                ),
              ),
              const SizedBox(height: 16),

              // Website
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(
                  labelText: 'Website',
                  hintText: 'Enter your company website URL',
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 16),

              // Company Description
              TextFormField(
                controller: _companyDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Company Description',
                  hintText: 'Describe your company',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 5,
                validator: (value) => Validators.validateRequired(
                  value,
                  'Company description',
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
            ],
          ),
        ),
      ),
    );
  }
}