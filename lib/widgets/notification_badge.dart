import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasklink2/services/auth_service.dart';
import 'package:tasklink2/services/notification_service.dart';

import '../screens/notification_screen.dart';

class NotificationBadge extends StatefulWidget {
  final Widget child;
  final double right;
  final double top;

  const NotificationBadge({
    Key? key,
    required this.child,
    this.right = -5,
    this.top = -5,
  }) : super(key: key);

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  @override
  void initState() {
    super.initState();
    // Load notifications when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
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
    final unreadCount = notificationService.unreadCount;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            );
            // Refresh notifications after returning
            _loadNotifications();
          },
          child: widget.child,
        ),
        if (unreadCount > 0)
          Positioned(
            right: widget.right,
            top: widget.top,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}