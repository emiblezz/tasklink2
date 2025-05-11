class AppConstants {
  // App info
  static const String appName = 'TaskLink';
  static const String appVersion = '1.0.0';

  // Route names
  static const String splashRoute = '/splash';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String jobSeekerHomeRoute = '/job-seeker-home';
  static const String recruiterHomeRoute = '/recruiter-home';

  // Error messages
  static const String networkErrorMessage = 'Network connection error. Please check your internet connection.';
  static const String authErrorMessage = 'Authentication error. Please try again.';
  static const String generalErrorMessage = 'An error occurred. Please try again later.';

  // Success messages
  static const String registrationEmailConfirmMessage = 'Registration submitted! Please check your email to confirm your account.';
  static const String loginSuccessMessage = 'Login successful!';

  // Validation messages
  static const String emailRequiredMessage = 'Email is required';
  static const String invalidEmailMessage = 'Please enter a valid email';
  static const String passwordRequiredMessage = 'Password is required';
  static const String weakPasswordMessage = 'Password must be at least 8 characters with a number and special character';
  static const String nameRequiredMessage = 'Name is required';
  static const String phoneRequiredMessage = 'Phone number is required';
  static const String invalidPhoneMessage = 'Please enter a valid phone number';

  // User roles
  static const int jobSeekerRoleId = 1;
  static const int recruiterRoleId = 2;
  static const int adminRoleId = 3;

  // Application statuses
  static const String pendingStatus = 'Pending';
  static const String selectedStatus = 'Selected';
  static const String rejectedStatus = 'Rejected';

  // Job statuses
  static const String openStatus = 'Open';
  static const String closedStatus = 'Closed';

  // Storage keys
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String roleKey = 'user_role';
  static const String rememberMeKey = 'remember_me';
  static const String sessionExpiryKey = 'session_expiry';
}