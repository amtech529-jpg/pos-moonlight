import 'package:flutter/material.dart';
import '../models/api_response.dart';

class CategoryErrorHandler {
  static void showErrorSnackBar(
      BuildContext context,
      String message, {
        Duration duration = const Duration(seconds: 4),
        SnackBarAction? action,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: action,
      ),
    );
  }

  static void showSuccessSnackBar(
      BuildContext context,
      String message, {
        Duration duration = const Duration(seconds: 3),
        SnackBarAction? action,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: action,
      ),
    );
  }

  static void showWarningSnackBar(
      BuildContext context,
      String message, {
        Duration duration = const Duration(seconds: 3),
        SnackBarAction? action,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.warning_outlined,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: action,
      ),
    );
  }

  static void showInfoSnackBar(
      BuildContext context,
      String message, {
        Duration duration = const Duration(seconds: 3),
        SnackBarAction? action,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: action,
      ),
    );
  }

  static void handleApiError(
      BuildContext context,
      ApiError error, {
        VoidCallback? onRetry,
        VoidCallback? onDismiss,
      }) {
    String message = error.displayMessage;

    // Customize message based on error type
    switch (error.type) {
      case 'network_error':
        message = 'Network connection error. Please check your internet connection and try again.';
        break;
      case 'timeout_error':
        message = 'Request timeout. Please try again.';
        break;
      case 'server_error':
        message = 'Server error occurred. Please try again later.';
        break;
      default:
        message = error.displayMessage;
    }

    SnackBarAction? action;
    if (onRetry != null) {
      action = SnackBarAction(
        label: 'Retry',
        textColor: Colors.white,
        onPressed: onRetry,
      );
    }

    showErrorSnackBar(
      context,
      message,
      duration: const Duration(seconds: 5),
      action: action,
    );
  }

  static void showLoadingDialog(
      BuildContext context, {
        String message = 'Loading...',
      }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  static Future<bool?> showConfirmDialog(
      BuildContext context, {
        required String title,
        required String message,
        String confirmText = 'Confirm',
        String cancelText = 'Cancel',
        Color? confirmColor,
        IconData? icon,
      }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: confirmColor ?? Colors.red),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelText,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              confirmText,
              style: TextStyle(
                color: confirmColor ?? Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<bool?> showDeleteConfirmDialog(
      BuildContext context, {
        required String itemName,
        String? additionalMessage,
        bool isPermanent = true, // New parameter to indicate permanent deletion
      }) async {
    return await showConfirmDialog(
      context,
      title: isPermanent ? 'Delete Category Permanently' : 'Delete Category',
      message: additionalMessage ??
          (isPermanent
              ? 'Are you sure you want to permanently delete "$itemName"? This action cannot be undone and the category will be completely removed from the database.'
              : 'Are you sure you want to delete "$itemName"? This action cannot be undone.'),
      confirmText: isPermanent ? 'Delete Permanently' : 'Delete',
      cancelText: 'Cancel',
      confirmColor: Colors.red,
      icon: isPermanent ? Icons.delete_forever_rounded : Icons.warning_rounded,
    );
  }

  static Future<bool?> showSoftDeleteConfirmDialog(
      BuildContext context, {
        required String itemName,
        String? additionalMessage,
      }) async {
    return await showConfirmDialog(
      context,
      title: 'Deactivate Category',
      message: additionalMessage ??
          'Are you sure you want to deactivate "$itemName"? The category will be hidden but can be restored later.',
      confirmText: 'Deactivate',
      cancelText: 'Cancel',
      confirmColor: Colors.orange,
      icon: Icons.visibility_off_rounded,
    );
  }

  static void showNetworkErrorDialog(
      BuildContext context, {
        VoidCallback? onRetry,
      }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.orange),
            SizedBox(width: 12),
            Text('Connection Error'),
          ],
        ),
        content: const Text(
          'Unable to connect to the server. Please check your internet connection and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  static void showValidationErrorDialog(
      BuildContext context, {
        required Map<String, dynamic> errors,
      }) {
    final errorMessages = <String>[];

    errors.forEach((field, messages) {
      if (messages is List) {
        for (var message in messages) {
          errorMessages.add('• $message');
        }
      } else {
        errorMessages.add('• $messages');
      }
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 12),
            Text('Validation Error'),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            errorMessages.join('\n'),
            style: const TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void showOfflineMessage(BuildContext context) {
    showInfoSnackBar(
      context,
      'You are offline. Some features may not be available.',
      duration: const Duration(seconds: 2),
    );
  }

  static void showCacheMessage(BuildContext context) {
    showInfoSnackBar(
      context,
      'Showing cached data. Pull to refresh for latest updates.',
      duration: const Duration(seconds: 3),
    );
  }

  static void showEmptyStateMessage(
      BuildContext context, {
        String message = 'No categories found.',
      }) {
    showInfoSnackBar(
      context,
      message,
      duration: const Duration(seconds: 2),
    );
  }

  static void showPaginationError(
      BuildContext context, {
        VoidCallback? onRetry,
      }) {
    showErrorSnackBar(
      context,
      'Failed to load more items.',
      action: onRetry != null
          ? SnackBarAction(
        label: 'Retry',
        textColor: Colors.white,
        onPressed: onRetry,
      )
          : null,
    );
  }

  // Category-specific error messages
  static String getCategoryErrorMessage(String errorType) {
    switch (errorType) {
      case 'category_name_required':
        return 'Category name is required';
      case 'category_name_too_long':
        return 'Category name is too long (max 50 characters)';
      case 'category_name_exists':
        return 'A category with this name already exists';
      case 'category_not_found':
        return 'Category not found';
      case 'category_in_use':
        return 'Category cannot be deleted because it is being used';
      case 'category_already_deleted':
        return 'Category has already been deleted';
      case 'category_description_too_long':
        return 'Description is too long (max 200 characters)';
      default:
        return 'An error occurred while processing the category';
    }
  }
}