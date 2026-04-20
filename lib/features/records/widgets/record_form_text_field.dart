import 'package:flutter/material.dart';
import 'package:recolle/core/theme/app_colors.dart';

class RecordFormTextField extends StatelessWidget {
  const RecordFormTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.maxLength,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      style: const TextStyle(color: AppColors.textPrimary),
      cursorColor: AppColors.gold,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7)),
        prefixIcon: Icon(
          icon,
          color: AppColors.gold.withValues(alpha: 0.7),
          size: 20,
        ),
        filled: true,
        fillColor: AppColors.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.textDisabled.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold),
        ),
        alignLabelWithHint: true,
      ),
    );
  }
}
