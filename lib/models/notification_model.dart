import 'dart:convert';
import 'package:intl/intl.dart';

class NotificationModel {
  final int id;
  final String userId;
  final String message;
  final String type;
  final String status;
  final DateTime? createdAt;
  // We'll keep these properties in the model for UI purposes, but handle them differently when interacting with the database
  final String? iconName; // Not in DB, derived from type
  final Map<String, dynamic>? data; // Not in DB

  NotificationModel({
    required this.id,
    required this.userId,
    required this.message,
    required this.type,
    required this.status,
    this.createdAt,
    this.iconName,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Extract the base notification
    final notification = NotificationModel(
      id: json['notification_id'],
      userId: json['user_id'],
      message: json['notification_message'] ?? json['message'] ?? '',
      type: json['notification_type'] ?? json['type'] ?? '',
      status: json['status'] ?? 'Unread',
      createdAt: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : (json['created_at'] != null ? DateTime.parse(json['created_at']) : null),
      // Derive iconName from type since it's not in the database
      iconName: _getIconForType(json['notification_type'] ?? json['type'] ?? ''),
      // Handle data carefully as it's not in the database schema
      data: null,
    );

    return notification;
  }

  Map<String, dynamic> toJson() {
    // Only include fields that exist in the database
    return {
      'notification_id': id,
      'user_id': userId,
      'notification_message': message,
      'notification_type': type,
      'status': status,
      'timestamp': createdAt?.toIso8601String(),
      // Omit iconName and data as they don't exist in DB
    };
  }

  // For database insert operations, create a special method
  Map<String, dynamic> toDbJson() {
    // Only include fields that exist in the database
    return {
      // Don't include notification_id as it's auto-generated
      'user_id': userId,
      'notification_message': message,
      'notification_type': type,
      'status': status,
      'timestamp': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  // Helper method to derive an icon from notification type
  static String? _getIconForType(String type) {
    switch (type) {
      case 'application':
        return 'description';
      case 'application_update':
      case 'status_update':
        return 'update';
      case 'job_match':
        return 'work';
      case 'recruiter_feedback':
        return 'comment';
      case 'message':
        return 'mail';
      case 'test':
        return 'notifications';
      default:
        return 'notifications';
    }
  }

  // Add the copyWith method
  NotificationModel copyWith({
    int? id,
    String? userId,
    String? message,
    String? type,
    String? status,
    DateTime? createdAt,
    String? iconName,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      message: message ?? this.message,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      iconName: iconName ?? this.iconName,
      data: data ?? this.data,
    );
  }

  // Add this getter for the formatted time
  String get formattedTime {
    if (createdAt == null) return '';

    final now = DateTime.now();
    final difference = now.difference(createdAt!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hr ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      // Make sure to import 'package:intl/intl.dart' at the top
      final DateFormat formatter = DateFormat('MMM dd, yyyy');
      return formatter.format(createdAt!);
    }
  }
}