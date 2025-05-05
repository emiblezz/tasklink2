import 'package:intl/intl.dart';

class NotificationModel {
  final int id;
  final String userId;
  final String type;
  final String message;
  final DateTime timestamp;
  final String status; // 'Read' or 'Unread'

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    required this.timestamp,
    required this.status,
  });

  // Create a copy with modified fields
  NotificationModel copyWith({
    int? id,
    String? userId,
    String? type,
    String? message,
    DateTime? timestamp,
    String? status,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }

  // Factory constructor to create NotificationModel from JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['notification_id'],
      userId: json['user_id'],
      type: json['notification_type'],
      message: json['notification_message'],
      timestamp: DateTime.parse(json['timestamp']),
      status: json['status'],
    );
  }

  // Convert NotificationModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'notification_id': id,
      'user_id': userId,
      'notification_type': type,
      'notification_message': message,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
    };
  }

  // Get icon based on notification type
  String get iconName {
    switch (type) {
      case 'application':
        return 'description';
      case 'status_update':
        return 'update';
      case 'job_match':
        return 'work';
      case 'message':
        return 'mail';
      default:
        return 'notifications';
    }
  }

  // Format the timestamp for display
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      // More than a week ago - show date
      return DateFormat('MMM d, yyyy').format(timestamp);
    } else if (difference.inDays > 0) {
      // Days ago
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      // Hours ago
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      // Minutes ago
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      // Just now
      return 'just now';
    }
  }
}