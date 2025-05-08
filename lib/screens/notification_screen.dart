import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasklink2/models/notification_model.dart';
import 'package:tasklink2/services/auth_service.dart';
import 'package:tasklink2/services/notification_service.dart';
import 'package:tasklink2/services/job_service.dart';
import 'package:tasklink2/screens/job_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch notifications when screen loads
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final notificationService = Provider.of<NotificationService>(context, listen: false);

    if (authService.currentUser != null) {
      await notificationService.fetchNotifications(authService.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationService = Provider.of<NotificationService>(context);
    final notifications = notificationService.notifications;
    final isLoading = notificationService.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Mark all as read',
              onPressed: () {
                final authService = Provider.of<AuthService>(context, listen: false);
                if (authService.currentUser != null) {
                  notificationService.markAllAsRead(authService.currentUser!.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All notifications marked as read')),
                  );
                }
              },
            ),
        ],
      ),
      body: _buildBody(context, notifications, isLoading),
    );
  }

  Widget _buildBody(BuildContext context, List<NotificationModel> notifications, bool isLoading) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'You\'ll be notified about application updates and recruiter feedback',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return Dismissible(
            key: Key('notification_${notification.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
            onDismissed: (direction) {
              // Get notificationService from Provider inside the callback
              final notificationService = Provider.of<NotificationService>(context, listen: false);
              notificationService.deleteNotification(notification.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification deleted')),
              );
            },
            child: _NotificationTile(
              notification: notification,
              onTap: () => _handleNotificationTap(notification),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    // Mark as read
    if (notification.status == 'Unread') {
      Provider.of<NotificationService>(context, listen: false)
          .markAsRead(notification.id);
    }

    // Handle navigation based on notification type and data
    if (notification.data != null) {
      try {
        // Handle application status updates
        if (notification.type == 'status_update' || notification.type == 'application_update') {
          final jobService = Provider.of<JobService>(context, listen: false);
          final jobId = int.tryParse(notification.data!['job_id'] ?? '');

          if (jobId != null) {
            // Show loading indicator
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );

            try {
              final job = await jobService.getJobById(jobId);

              // Close loading indicator
              if (mounted) Navigator.pop(context);

              if (job != null && mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JobDetailScreen(job: job),
                  ),
                );
                return;
              }
            } catch (e) {
              // Close loading indicator
              if (mounted) Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error loading job details: $e')),
              );
            }
          }
        }

        // Handle recruiter feedback
        else if (notification.type == 'recruiter_feedback') {
          final jobService = Provider.of<JobService>(context, listen: false);
          final jobId = int.tryParse(notification.data!['job_id'] ?? '');
          final applicationId = notification.data!['application_id'];

          if (jobId != null) {
            // Show loading indicator
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );

            try {
              final job = await jobService.getJobById(jobId);

              // Close loading indicator
              if (mounted) Navigator.pop(context);

              if (job != null && mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JobDetailScreen(
                      job: job,
                      showFeedback: true,
                      applicationId: int.tryParse(applicationId ?? ''),
                    ),
                  ),
                );
                return;
              }
            } catch (e) {
              // Close loading indicator
              if (mounted) Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error loading job details: $e')),
              );
            }
          }
        }
      } catch (e) {
        print('Error handling notification tap: $e');
      }
    }

    // For other notification types or if there was an error
    switch (notification.type) {
      case 'application':
      case 'job_match':
      case 'message':
      // Default handling if specific data handling failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(notification.message)),
        );
        break;
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Enhanced notification tile with better status visualization
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: notification.status == 'Unread'
          ? Colors.blue.shade50
          : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon with background
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification.type).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getNotificationIcon(notification.type, notification.iconName),
                  color: _getNotificationColor(notification.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title - extract from notification.message
                    Text(
                      _getNotificationTitle(notification),
                      style: TextStyle(
                        fontWeight: notification.status == 'Unread'
                            ? FontWeight.bold
                            : FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Message
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Time and status indicator
                    Row(
                      children: [
                        Text(
                          notification.formattedTime,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        if (notification.status == 'Unread')
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to extract a title from the notification message
  String _getNotificationTitle(NotificationModel notification) {
    // For recruiter feedback
    if (notification.type == 'recruiter_feedback') {
      return 'Recruiter Feedback';
    }

    // For application status updates
    if (notification.type == 'status_update' || notification.type == 'application_update') {
      if (notification.data != null) {
        final status = notification.data!['status'];
        if (status == 'Selected') {
          return 'Application Selected! 🎉';
        } else if (status == 'Rejected') {
          return 'Application Update';
        }
      }
      return 'Application Status Update';
    }

    // For job matches
    if (notification.type == 'job_match') {
      return 'New Job Match';
    }

    // For messages
    if (notification.type == 'message') {
      return 'New Message';
    }

    // Default title - use the first part of the message
    final messageParts = notification.message.split(' ');
    if (messageParts.length > 3) {
      return '${messageParts.take(3).join(' ')}...';
    }
    return notification.message;
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'application':
      case 'application_update':
        return Colors.blue;
      case 'status_update':
        return Colors.green;
      case 'job_match':
        return Colors.purple;
      case 'message':
        return Colors.orange;
      case 'recruiter_feedback':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type, String? iconName) {
    // First check notification type for specific icons
    switch (type) {
      case 'application_update':
      case 'status_update':
        return Icons.update;
      case 'recruiter_feedback':
        return Icons.comment;
    }

    // If no type-specific icon, check iconName
    if (iconName != null) {
      switch (iconName) {
        case 'description':
          return Icons.description;
        case 'update':
          return Icons.update;
        case 'work':
          return Icons.work;
        case 'mail':
          return Icons.mail;
      }
    }

    // Default
    return Icons.notifications;
  }
}