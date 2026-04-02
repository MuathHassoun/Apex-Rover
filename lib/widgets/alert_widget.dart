import 'package:flutter/material.dart';
import '../config/theme.dart';

enum AlertType {
  info,
  warning,
  error,
  critical,
  success,
}

class AlertWidget extends StatelessWidget {
  final String title;
  final String message;
  final AlertType type;
  final VoidCallback? onDismiss;

  const AlertWidget({
    Key? key,
    required this.title,
    required this.message,
    required this.type,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, borderColor, iconColor, icon) =
        _getAlertStyles(type);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close,
                color: iconColor,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  (Color, Color, Color, IconData) _getAlertStyles(AlertType type) {
    return switch (type) {
      AlertType.info => (
          AppColors.info.withOpacity(0.1),
          AppColors.info,
          AppColors.info,
          Icons.info,
        ),
      AlertType.warning => (
          AppColors.warning.withOpacity(0.1),
          AppColors.warning,
          AppColors.warning,
          Icons.warning,
        ),
      AlertType.error => (
          AppColors.error.withOpacity(0.1),
          AppColors.error,
          AppColors.error,
          Icons.error,
        ),
      AlertType.critical => (
          AppColors.error.withOpacity(0.15),
          AppColors.error,
          AppColors.error,
          Icons.dangerous,
        ),
      AlertType.success => (
          AppColors.success.withOpacity(0.1),
          AppColors.success,
          AppColors.success,
          Icons.check_circle,
        ),
    };
  }
}

class AlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final AlertType type;
  final List<Widget> actions;

  const AlertDialog({
    Key? key,
    required this.title,
    required this.message,
    required this.type,
    required this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }
}
