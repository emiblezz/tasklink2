import 'dart:convert';
import 'package:intl/intl.dart';

class NotificationModel {
  final int id;
  final String userId;
  final String message;
  final String type;
  final String status;
  final DateTime? createdAt;
  final String? iconName;
  final Map<String, dynamic>? data;

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
    return NotificationModel(
      id: json['notification_id'],
      userId: json['user_id'],
      message: json['notification_message'] ?? json['message'] ?? '',
      type: json['notification_type'] ?? json['type'] ?? '',
      status: json['status'] ?? 'Unread',
      createdAt: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : (json['created_at'] != null ? DateTime.parse(json['created_at']) : null),
      iconName: json['icon_name'],
      data: json['data'] != null
          ? (json['data'] is String
          ? jsonDecode(json['data'])
          : json['data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notification_id': id,
      'user_id': userId,
      'notification_message': message,
      'notification_type': type,
      'status': status,
      'timestamp': createdAt?.toIso8601String(),
      'icon_name': iconName,
      'data': data != null ? jsonEncode(data) : null,
    };
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