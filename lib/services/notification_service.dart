import 'package:flutter/foundation.dart';
import 'package:supabase/supabase.dart';
import 'package:tasklink2/models/notification_model.dart';
import 'package:tasklink2/config/app_config.dart';

class NotificationService extends ChangeNotifier {
  // Use direct Supabase client instead of service
  final SupabaseClient _supabase = AppConfig().supabaseClient;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  // Fetch notifications for a user
  Future<void> fetchNotifications(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('Fetching notifications for user: $userId');

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false);

      debugPrint('Notification response received, items: ${response?.length ?? 0}');

      if (response != null && response is List) {
        _notifications = response
            .map<NotificationModel>((json) => NotificationModel.fromJson(json))
            .toList();

        _unreadCount = _notifications.where((n) => n.status == 'Unread').length;
        debugPrint('Loaded ${_notifications.length} notifications, $_unreadCount unread');
      } else {
        _notifications = [];
        _unreadCount = 0;
        debugPrint('No notifications found or invalid response format');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      _isLoading = false;
      _notifications = [];
      _unreadCount = 0;
      notifyListeners();
    }
  }

  // Create a new notification - direct Supabase client
  Future<void> createNotification({
    required String userId,
    required String notificationType,
    required String message,
  }) async {
    try {
      debugPrint('Creating notification for user: $userId, type: $notificationType');

      await _supabase.from('notifications').insert({
        'user_id': userId,
        'notification_type': notificationType,
        'notification_message': message,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'Unread',
      });

      debugPrint('Notification created successfully');

      // If this notification is for the user whose notifications we're currently displaying
      // then refresh the list
      if (_notifications.isNotEmpty && _notifications.first.userId == userId) {
        await fetchNotifications(userId);
      }
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }

  // Mark a notification as read
  Future<void> markAsRead(int notificationId) async {
    try {
      debugPrint('Marking notification as read: $notificationId');

      await _supabase
          .from('notifications')
          .update({'status': 'Read'})
          .eq('notification_id', notificationId);

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && _notifications[index].status == 'Unread') {
        _notifications[index] = _notifications[index].copyWith(status: 'Read');
        _unreadCount = max(0, _unreadCount - 1);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      debugPrint('Marking all notifications as read for user: $userId');

      await _supabase
          .from('notifications')
          .update({'status': 'Read'})
          .eq('user_id', userId)
          .eq('status', 'Unread');

      for (int i = 0; i < _notifications.length; i++) {
        if (_notifications[i].status == 'Unread') {
          _notifications[i] = _notifications[i].copyWith(status: 'Read');
        }
      }

      _unreadCount = 0;
      notifyListeners();

      debugPrint('All notifications marked as read successfully');
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  // Delete a notification
  Future<void> deleteNotification(int notificationId) async {
    try {
      debugPrint('Deleting notification: $notificationId');

      await _supabase
          .from('notifications')
          .delete()
          .eq('notification_id', notificationId);

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        if (_notifications[index].status == 'Unread') {
          _unreadCount = max(0, _unreadCount - 1);
        }
        _notifications.removeAt(index);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  // ADDED MISSING METHODS:

  // Notify about job application
  Future<void> notifyJobApplication({
    required String recruiterId,
    required String jobTitle,
    required String applicantName
  }) async {
    debugPrint('Creating job application notification for recruiter: $recruiterId');
    await createNotification(
      userId: recruiterId,
      notificationType: 'application',
      message: '$applicantName has applied for the position: $jobTitle',
    );
  }

  // Notify about application status change
  Future<void> notifyStatusChange({
    required String applicantId,
    required String jobTitle,
    required String status,
  }) async {
    debugPrint('Creating status change notification for applicant: $applicantId');
    await createNotification(
      userId: applicantId,
      notificationType: 'status_update',
      message: 'Your application for $jobTitle has been $status',
    );
  }

  // Notify about new job
  Future<void> notifyNewJob({
    required List<String> jobSeekerIds,
    required String jobTitle,
    required String companyName,
  }) async {
    debugPrint('Creating new job notifications for ${jobSeekerIds.length} job seekers');
    for (final userId in jobSeekerIds) {
      await createNotification(
        userId: userId,
        notificationType: 'job_match',
        message: 'New job opportunity: $jobTitle at $companyName',
      );
    }
  }

  // Helper function for max value
  int max(int a, int b) {
    return a > b ? a : b;
  }
}