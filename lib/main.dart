import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tasklink2/config/app_config.dart';
import 'package:tasklink2/screens/auth/splash_screen.dart';
import 'package:tasklink2/services/analytics_service.dart';
import 'package:tasklink2/services/auth_service.dart';
import 'package:tasklink2/services/job_service.dart';
import 'package:tasklink2/services/notification_service.dart';
import 'package:tasklink2/services/profile_service.dart';
import 'package:tasklink2/services/ranking_service.dart';
import 'package:tasklink2/services/recruiter_profile_service.dart' show RecruiterProfileService;
import 'package:tasklink2/services/search_history_service.dart';
import 'package:tasklink2/services/search_service.dart';
import 'package:tasklink2/services/ai_services.dart';
import 'package:tasklink2/utils/deep_link_handler.dart';
import 'package:tasklink2/utils/theme.dart';

void main() {
  // Wrap everything in error handling
  runZonedGuarded(() async {
    // Add error logging for Flutter errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('Flutter Error: ${details.exception}');
      debugPrint('Stack trace: ${details.stack}');
    };

    try {
      // Ensure Flutter is initialized first
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize Supabase with minimal config (hardcoded fallbacks)
      await AppConfig().initializeWithFallback();

      // Attempt to set up deep links - but continue if it fails
      try {
        await DeepLinkHandler.setupDeepLinks();
      } catch (e) {
        debugPrint('Deep links setup failed: $e');
        // Continue without deep links
      }

      // Run the app
      runApp(const MyApp());
    } catch (e, stackTrace) {
      // Show error on crash
      debugPrint('Fatal initialization error: $e');
      debugPrint('Stack trace: $stackTrace');

      // Run a minimal error app
      runApp(MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 80),
                  const SizedBox(height: 16),
                  const Text(
                    'App Initialization Error',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text('Error details: $e'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Try to restart the app
                      main();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ));
    }
  }, (error, stack) {
    // Log any uncaught errors
    debugPrint('Uncaught error: $error');
    debugPrint('Stack trace: $stack');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Use Provider.value for services to avoid re-creation
        Provider.value(value: AppConfig()),

        // Safely create AIService
        Provider(
          create: (context) {
            try {
              return AIService(baseUrl: AppConfig.backendUrl);
            } catch (e) {
              debugPrint('Error creating AIService: $e');
              // Return with fallback URL
              return AIService(baseUrl: 'https://bse25-34-fyp-backend.onrender.com');
            }
          },
        ),

        // Create other services with error handling
        ChangeNotifierProvider(
          create: (_) => AuthService(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationService(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileService(),
        ),
        ChangeNotifierProvider(
          create: (_) => SearchService(),
        ),
        ChangeNotifierProvider(
          create: (_) => AnalyticsService(),
        ),
        ChangeNotifierProvider(create: (_) => RecruiterProfileService()),

        // Create RankingService safely with all dependencies
        Provider(
          create: (context) {
            final aiService = Provider.of<AIService>(context, listen: false);
            return RankingService(
              supabaseClient: AppConfig().supabaseClient,
              aiService: aiService,
            );
          },
        ),
        ChangeNotifierProvider(create: (_) => SearchHistoryService()),
        // JobService with its dependencies
        ChangeNotifierProxyProvider2<AuthService, NotificationService, JobService>(
          create: (_) => JobService(),
          update: (_, authService, notificationService, jobService) {
            jobService!.setAuthService(authService);
            jobService.setNotificationService(notificationService);
            return jobService;
          },
        ),
      ],
      child: Builder(
        builder: (context) {
          // Wrap the app in error handling
          return MaterialApp(
            title: 'TaskLink',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            debugShowCheckedModeBanner: false,
            navigatorKey: DeepLinkHandler.navigatorKey,
            // Start with a simple error-resistant screen
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}