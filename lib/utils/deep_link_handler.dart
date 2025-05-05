import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tasklink2/screens/auth/reset_password_screen.dart';
//import 'package:uni_links/uni_links.dart';
import 'package:app_links/app_links.dart';

class DeepLinkHandler {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static StreamSubscription? _subscription;
  static final AppLinks _appLinks = AppLinks();

  static Future<void> setupDeepLinks() async {
    // Handle deep link when app is started by a link
    try {
      final initialLink = await _appLinks.getInitialAppLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink.toString());
      }
    } on PlatformException {
      // Error getting initial link
    }

    // Listen for deep links when app is already running
    _subscription = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri.toString());
      }
    }, onError: (err) {
      // Handle errors
    });
  }

  static void dispose() {
    _subscription?.cancel();
  }

  static void _handleDeepLink(String link) {
    final uri = Uri.parse(link);

    // Handle password reset link
    if (uri.path.contains('reset-password')) {
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (_) => const ResetPasswordScreen(),
          ),
        );
      }
    }

    // Handle auth callback (email verification)
    else if (uri.path.contains('auth/callback')) {
      // Email was verified
      // You could show a success message or redirect to login
      if (navigatorKey.currentState != null) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}