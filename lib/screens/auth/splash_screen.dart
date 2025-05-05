import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:tasklink2/screens/auth/login_screen.dart';
import 'package:tasklink2/screens/job_seeker/job_seeker_home_screen.dart';
import 'package:tasklink2/screens/recruiter/recruiter_home_screen.dart';
import 'package:tasklink2/services/auth_service.dart';
import 'package:tasklink2/utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Check authentication status after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      _checkAuthStatus();
    });
  }

  // Check if user is authenticated and navigate accordingly
  Future<void> _checkAuthStatus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.initialize();

    if (!mounted) return;

    if (authService.isAuthenticated) {
      // Navigate based on user role
      if (authService.isJobSeeker) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const JobSeekerHomeScreen()),
        );
      } else if (authService.isRecruiter) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RecruiterHomeScreen()),
        );
      } else {
        // Default to login if role is unknown
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } else {
      // Not authenticated, go to login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  'TL',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // App name
            Text(
              AppConstants.appName,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            // App description
            const Text(
              'Connect with the right opportunities',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),

            // Loading indicator
            const SpinKitPulsingGrid(
              color: Colors.white,
              size: 40.0,
            ),
          ],
        ),
      ),
    );
  }
}