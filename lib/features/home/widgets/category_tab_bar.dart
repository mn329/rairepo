import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:recolle/features/home/models/recolle_category.dart';
import 'package:recolle/features/home/providers/home_providers.dart';
import 'package:recolle/theme/app_colors.dart';

class CategoryTabBar extends ConsumerWidget {
  const CategoryTabBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: RecolleCategory.values.map((category) {
          final isSelected = category == selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category.label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  ref.read(selectedCategoryProvider.notifier).state = category;
                }
              },
              backgroundColor: AppColors.surfaceLight,
              selectedColor: AppColors.gold.withOpacity(0.2),
              checkmarkColor: AppColors.gold,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.gold : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.gold : Colors.transparent,
                  width: 1,
                ),
              ),
              showCheckmark: false,
              avatar: isSelected
                  ? null
                  : Icon(
                      category.icon,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
