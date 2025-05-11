import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase/supabase.dart';  // Changed from supabase_flutter to supabase
import 'package:tasklink2/config/app_config.dart';
import 'package:tasklink2/models/user_model.dart';
import 'package:tasklink2/services/supabase_service.dart';
import 'package:tasklink2/utils/constants.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabaseClient = AppConfig().supabaseClient;
  final SupabaseService _supabaseService = SupabaseService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _rememberMe = false;
  bool get rememberMe => _rememberMe;

  UserModel? get currentUser => _currentUser;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _currentUser != null;

  bool get isJobSeeker => _currentUser?.roleId == AppConstants.jobSeekerRoleId;

  bool get isRecruiter => _currentUser?.roleId == AppConstants.recruiterRoleId;

  bool get isAdmin => _currentUser?.roleId == AppConstants.adminRoleId;

  set rememberMe(bool value) {
    _rememberMe = value;
    _saveRememberMePreference(value);
    notifyListeners();
  }

  Future<void> _loadRememberMePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _rememberMe = prefs.getBool(AppConstants.rememberMeKey) ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading remember me preference: $e');
    }
  }

  Future<void> _saveRememberMePreference(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.rememberMeKey, value);
    } catch (e) {
      debugPrint('Error saving remember me preference: $e');
    }
  }

  // Initialize and check if user is already logged in
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load remember me preference
      await _loadRememberMePreference();

      // Check for session expiry if rememberMe was false
      final prefs = await SharedPreferences.getInstance();
      final sessionExpiry = prefs.getInt(AppConstants.sessionExpiryKey);

      if (sessionExpiry != null) {
        final expiryDate = DateTime.fromMillisecondsSinceEpoch(sessionExpiry);
        if (DateTime.now().isAfter(expiryDate)) {
          // Session expired, sign out
          await logout();
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      // Check if user is already authenticated
      final authUser = _supabaseClient.auth.currentUser;
      if (authUser != null) {
        debugPrint("Found authenticated user: ${authUser.id}");
        // Get user data from database
        _currentUser = await _supabaseService.getUserById(authUser.id);

        // If user exists in auth but not in database, create a record
        if (_currentUser == null) {
          debugPrint("User not found in database, creating record");

          final userData = authUser.userMetadata;
          final name = userData?['name'] as String? ?? authUser.email?.split('@')[0] ?? 'User';
          final email = authUser.email ?? '';
          final phone = userData?['phone'] as String? ?? '';
          final roleId = userData?['role_id'] as int? ?? AppConstants.jobSeekerRoleId;

          final newUser = UserModel(
            id: authUser.id,
            name: name,
            email: email,
            phone: phone,
            roleId: roleId,
            profileStatus: 'Incomplete',
          );

          _currentUser = await _supabaseService.createOrUpdateUser(newUser);
          debugPrint("User record created: ${_currentUser != null}");
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Error in initialize: $_errorMessage");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register a new user
  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required int roleId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint("Checking if email already exists: $email");

      // Check if user already exists with this email
      final userExists = await userEmailExists(email);
      if (userExists) {
        _errorMessage = "An account with this email already exists. Please log in instead.";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      debugPrint("Registering user with email: $email, role: $roleId");

      // Create the auth user with redirectTo for email confirmation
      final authResponse = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone,
          'role_id': roleId,
        },
        emailRedirectTo: 'io.supabase.tasklink://auth/callback',
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create user');
      }

      debugPrint("User registered successfully: ${authResponse.user!.id}");

      // Create user in database too
      final newUser = UserModel(
        id: authResponse.user!.id,
        name: name,
        email: email,
        phone: phone,
        roleId: roleId,
        profileStatus: 'Incomplete',
      );

      // Save user to database
      final createdUser = await _supabaseService.createOrUpdateUser(newUser);
      if (createdUser == null) {
        debugPrint("Warning: Failed to create user record in database");
      } else {
        debugPrint("User record created in database");
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Registration error: $_errorMessage");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  // Log in a user
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint("Logging in user with email: $email");

      // Sign in with email and password
      final authResponse = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Failed to log in');
      }

      debugPrint("User authenticated successfully: ${authResponse.user!.id}");
      debugPrint("Getting user data from database");

      // Get user data from database
      _currentUser = await _supabaseService.getUserById(authResponse.user!.id);

      if (_currentUser == null) {
        debugPrint("User not found in database, creating record");

        // Print exactly what we're about to save
        final userData = authResponse.user!.userMetadata;
        debugPrint("Auth metadata: $userData");

        final newUserData = {
          'id': authResponse.user!.id,
          'name': userData?['name'] ?? email.split('@')[0],
          'email': email,
          'phone': userData?['phone'] ?? '',
          'role_id': userData?['role_id'] ?? AppConstants.jobSeekerRoleId,
          'profile_status': 'Incomplete',
        };

        debugPrint("Attempting to create user with data: $newUserData");

        // If user exists in auth but not in database, create a record
        final name = userData?['name'] as String? ?? email.split('@')[0];
        final phone = userData?['phone'] as String? ?? '';
        final roleId = userData?['role_id'] as int? ?? AppConstants.jobSeekerRoleId;

        final newUser = UserModel(
          id: authResponse.user!.id,
          name: name,
          email: email,
          phone: phone,
          roleId: roleId,
          profileStatus: 'Incomplete',
        );

        // Save user to database
        _currentUser = await _supabaseService.createOrUpdateUser(newUser);

        if (_currentUser == null) {
          debugPrint("Stack trace: ${StackTrace.current}");
          throw Exception('Failed to create user record in database');
        }
        debugPrint("Created user record in database");
      }

      // Save session data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          AppConstants.userDataKey, jsonEncode(_currentUser!.toJson()));
      await prefs.setInt(AppConstants.roleKey, _currentUser!.roleId);

      // If rememberMe is false, set a session expiry
      if (!_rememberMe) {
        // Session will expire after 1 day instead of the default longer time
        // We can't directly control session length, but we can clear it ourselves later
        await prefs.setInt(AppConstants.sessionExpiryKey,
            DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch);
      } else {
        // Remove any existing expiry
        await prefs.remove(AppConstants.sessionExpiryKey);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Login error: $e");
      debugPrint("Stack trace: ${StackTrace.current}");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> userEmailExists(String email) async {
    try {
      debugPrint("Checking if user with email exists: $email");

      // Use a Supabase query to check if the email already exists in the users table
      final response = await _supabaseClient
          .from('users')
          .select('email')
          .eq('email', email)
          .limit(1);

      // In the updated Supabase client, we directly get the data
      // If there's an error, it would throw an exception
      final data = response as List<dynamic>;
      return data.isNotEmpty;
    } catch (e) {
      debugPrint("Error checking if user exists: $e");
      return false; // In case of error, proceed with registration attempt
    }
  }

  // Log out a user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabaseClient.auth.signOut();
      _currentUser = null;

      // Clear saved session data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.userDataKey);
      await prefs.remove(AppConstants.roleKey);
      debugPrint("User logged out successfully");
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Logout error: $_errorMessage");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // The redirectTo parameter is crucial for making the email links work
      await _supabaseClient.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.tasklink://reset-password',
      );

      debugPrint("Password reset email sent to: $email");
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error sending password reset: ${e.toString()}';
      debugPrint("Password reset error: $_errorMessage");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    required String name,
    required String phone,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Update user in database
      final updatedUser = _currentUser!.copyWith(
        name: name,
        phone: phone,
      );

      debugPrint("Updating user profile: ${_currentUser!.id}");
      final result = await _supabaseService.createOrUpdateUser(updatedUser);

      if (result != null) {
        _currentUser = result;

        // Update saved session data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            AppConstants.userDataKey, jsonEncode(_currentUser!.toJson()));

        debugPrint("User profile updated successfully");
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Profile update error: $_errorMessage");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> completePasswordReset(String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // This updates the user's password once they've clicked the email link
      final response = await _supabaseClient.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );

      if (response.user != null) {
        _currentUser = await _supabaseService.getUserById(response.user!.id);
        debugPrint("Password reset completed successfully");
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('Failed to update password');
      }
    } catch (e) {
      _errorMessage = 'Error resetting password: ${e.toString()}';
      debugPrint("Password reset error: $_errorMessage");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getReadableErrorMessage(String error) {
    if (error.contains('email not found')) {
      return 'This email is not registered in our system.';
    } else if (error.contains('invalid email')) {
      return 'Please enter a valid email address.';
    } else if (error.contains('too many requests')) {
      return 'Too many attempts. Please try again later.';
    } else if (error.contains('closed')) {
      return 'Connection error. Please check your internet.';
    }
    return 'An error occurred. Please try again.';
  }
}