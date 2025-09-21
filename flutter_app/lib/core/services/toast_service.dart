import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Toast service provider
final toastServiceProvider = Provider<ToastService>((ref) {
  return ToastService();
});

class ToastService {
  static final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = 
      GlobalKey<ScaffoldMessengerState>();

  static GlobalKey<ScaffoldMessengerState> get scaffoldMessengerKey => 
      _scaffoldMessengerKey;

  void showSuccess(String message) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
    );
  }

  void showError(String message) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.red,
      icon: Icons.error,
    );
  }

  void showInfo(String message) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.blue,
      icon: Icons.info,
    );
  }

  void showWarning(String message) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.orange,
      icon: Icons.warning,
    );
  }

  void showApprovalLinkSent(String link) {
    _showSnackBar(
      message: 'Approval link sent to customer',
      backgroundColor: Colors.green,
      icon: Icons.send,
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'View Link',
        textColor: Colors.white,
        onPressed: () {
          // Log to developer console for development
          debugPrint('Approval Link: $link');
        },
      ),
    );
  }

  void _showSnackBar({
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      action: action,
    );

    _scaffoldMessengerKey.currentState?.showSnackBar(snackBar);
  }

  void hideCurrentSnackBar() {
    _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
  }

  void clearSnackBars() {
    _scaffoldMessengerKey.currentState?.clearSnackBars();
  }
}