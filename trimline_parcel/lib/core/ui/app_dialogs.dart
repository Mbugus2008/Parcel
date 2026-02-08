import 'package:flutter/material.dart';

/// Confirmation dialog helper
class AppDialogs {
  AppDialogs._();

  /// Shows a confirmation dialog
  static Future<bool> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelText,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? (isDangerous ? Colors.red : null),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Shows delete confirmation
  static Future<bool> showDeleteConfirmation({
    required BuildContext context,
    String? itemName,
  }) {
    return showConfirmation(
      context: context,
      title: 'Delete ${itemName ?? 'Item'}?',
      message: 'This action cannot be undone. Are you sure you want to delete this ${itemName?.toLowerCase() ?? 'item'}?',
      confirmText: 'Delete',
      isDangerous: true,
    );
  }

  /// Shows logout confirmation
  static Future<bool> showLogoutConfirmation(BuildContext context) {
    return showConfirmation(
      context: context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmText: 'Logout',
    );
  }

  /// Shows an info dialog
  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.blue),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  /// Shows an error dialog
  static Future<void> showError({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  /// Shows a success dialog
  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  /// Shows a loading dialog
  static void showLoading(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(message),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Hides loading dialog
  static void hideLoading(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// Shows a bottom sheet with options
  static Future<T?> showOptions<T>({
    required BuildContext context,
    required String title,
    required List<OptionItem<T>> options,
  }) async {
    return showModalBottomSheet<T>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          ...options.map((option) => ListTile(
                leading: option.icon != null
                    ? Icon(option.icon, color: option.color)
                    : null,
                title: Text(
                  option.title,
                  style: TextStyle(color: option.color),
                ),
                subtitle: option.subtitle != null ? Text(option.subtitle!) : null,
                onTap: () => Navigator.of(context).pop(option.value),
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Option item for bottom sheet
class OptionItem<T> {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final T value;
  final Color? color;

  const OptionItem({
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.color,
  });
}
