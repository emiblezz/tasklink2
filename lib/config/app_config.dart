import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase/supabase.dart';

class AppConfig {
  // Singleton instance
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  // Supabase client with late initialization
  late SupabaseClient _supabaseClient;
  bool _isInitialized = false;

  // Check if initialized
  bool get isInitialized => _isInitialized;

  // Standard initialization
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('AppConfig already initialized');
      return;
    }

    try {
      // Load environment variables
      await dotenv.load().catchError((e) {
        debugPrint('Warning: Failed to load .env file: $e');
      });

      // Initialize Supabase client
      _supabaseClient = SupabaseClient(supabaseUrl, supabaseAnonKey);
      _isInitialized = true;

      debugPrint('AppConfig initialized successfully');
      debugPrint('Using Supabase URL: $supabaseUrl');
      debugPrint('Using backend URL: $backendUrl');
    } catch (e) {
      debugPrint('Error initializing AppConfig: $e');
      rethrow;
    }
  }

  // Fallback initialization that never throws
  Future<void> initializeWithFallback() async {
    try {
      await initialize();
    } catch (e) {
      debugPrint('Using fallback initialization due to error: $e');

      // Create client with hardcoded values if needed
      if (!_isInitialized) {
        _supabaseClient = SupabaseClient(
            'https://your-supabase-url.supabase.co',
            'your-anon-key'
        );
        _isInitialized = true;
      }
    }
  }

  // Expose the SupabaseClient with safety check
  SupabaseClient get supabaseClient {
    if (!_isInitialized) {
      debugPrint('Warning: Accessing supabaseClient before initialization!');
      // Create a default client to avoid crashes
      _supabaseClient = SupabaseClient(
          'https://your-supabase-url.supabase.co',
          'your-anon-key'
      );
      _isInitialized = true;
    }
    return _supabaseClient;
  }

  // Supabase configuration with printed warnings for missing values
  static String get supabaseUrl {
    final url = dotenv.env['SUPABASE_URL'];
    if (url == null || url.isEmpty) {
      debugPrint('WARNING: SUPABASE_URL not found in environment!');
      return 'https://your-supabase-url.supabase.co';
    }
    return url;
  }

  static String get supabaseAnonKey {
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    if (key == null || key.isEmpty) {
      debugPrint('WARNING: SUPABASE_ANON_KEY not found in environment!');
      return 'your-anon-key';
    }
    return key;
  }

  // AI Backend configuration
  static String get backendUrl {
    final url = dotenv.env['BACKEND_URL'];
    if (url == null || url.isEmpty) {
      return 'https://bse25-34-fyp-backend.onrender.com';
    }
    return url;
  }

  // App metadata
  static const String appName = 'TaskLink';
  static const String appVersion = '1.0.0';
}