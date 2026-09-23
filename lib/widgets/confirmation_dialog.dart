import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// A reusable confirmation dialog.
Future<bool?> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmText,
  Color confirmColor = AppColors.primary,
  IconData? icon,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      icon: icon != null
          ? Icon(icon, color: confirmColor, size: 36)
          : null,
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('CANCEL'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmColor,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(confirmText),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
