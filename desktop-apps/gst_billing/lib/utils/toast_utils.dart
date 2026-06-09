/// Toast & Notification Utilities
/// BillEase Accounts+ - Friendly error handling
library;

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Toast notification types
enum ToastType { success, error, warning, info }

/// Toast utility for showing user-friendly notifications
class Toast {
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final (color, icon) = switch (type) {
      ToastType.success => (AppTheme.successColor, Icons.check_circle),
      ToastType.error => (AppTheme.errorColor, Icons.error),
      ToastType.warning => (AppTheme.warningColor, Icons.warning),
      ToastType.info => (AppTheme.infoColor, Icons.info),
    };

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: duration,
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction ?? () {},
              )
            : null,
      ),
    );
  }

  /// Show success toast
  static void success(BuildContext context, String message) {
    show(context, message, type: ToastType.success);
  }

  /// Show error toast - Never show raw Python errors
  static void error(BuildContext context, String? rawError) {
    // Map common errors to friendly messages
    final message = _mapErrorToFriendlyMessage(rawError);
    show(
      context, 
      message, 
      type: ToastType.error,
      duration: const Duration(seconds: 5),
    );
  }

  /// Show warning toast
  static void warning(BuildContext context, String message) {
    show(context, message, type: ToastType.warning);
  }

  /// Show info toast
  static void info(BuildContext context, String message) {
    show(context, message, type: ToastType.info);
  }

  /// Show connection error toast with retry action
  static void connectionError(BuildContext context, {VoidCallback? onRetry}) {
    show(
      context,
      'Unable to sync data. Please check connection.',
      type: ToastType.error,
      duration: const Duration(seconds: 5),
      actionLabel: onRetry != null ? 'RETRY' : null,
      onAction: onRetry,
    );
  }

  /// Map raw errors to friendly messages
  static String _mapErrorToFriendlyMessage(String? rawError) {
    if (rawError == null) return 'Something went wrong. Please try again.';
    
    final error = rawError.toLowerCase();
    
    // Connection errors
    if (error.contains('socketexception') || 
        error.contains('connection refused') ||
        error.contains('network') ||
        error.contains('timeout')) {
      return 'Unable to sync data. Please check connection.';
    }
    
    // Authentication errors
    if (error.contains('401') || error.contains('unauthorized')) {
      return 'Session expired. Please login again.';
    }
    
    // Permission errors
    if (error.contains('403') || error.contains('forbidden')) {
      return 'You don\'t have permission for this action.';
    }
    
    // Not found errors
    if (error.contains('404') || error.contains('not found')) {
      return 'The requested item was not found.';
    }
    
    // Server errors
    if (error.contains('500') || error.contains('internal server')) {
      return 'Server error. Please try again later.';
    }
    
    // Validation errors
    if (error.contains('validation') || error.contains('invalid')) {
      return 'Please check your input and try again.';
    }
    
    // Database errors
    if (error.contains('database') || error.contains('duplicate')) {
      return 'Data conflict. Please refresh and try again.';
    }
    
    // Default friendly message
    return 'Something went wrong. Please try again.';
  }
}

/// Loading overlay utility
class LoadingOverlay {
  static OverlayEntry? _overlayEntry;

  static void show(BuildContext context, {String? message}) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
                ),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: const TextStyle(
                      color: AppTheme.slate600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

/// Confirmation dialog utility
class ConfirmDialog {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
    IconData? icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: confirmColor ?? AppTheme.primaryColor),
              const SizedBox(width: 12),
            ],
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppTheme.slate600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? AppTheme.primaryColor,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Show delete confirmation
  static Future<bool> delete(BuildContext context, String itemName) {
    return show(
      context,
      title: 'Delete $itemName?',
      message: 'This action cannot be undone.',
      confirmText: 'Delete',
      confirmColor: AppTheme.errorColor,
      icon: Icons.delete_outline,
    );
  }
}
