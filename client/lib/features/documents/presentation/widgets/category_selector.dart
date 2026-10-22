import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/document_categories.dart';

class CategorySelector extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: DocumentCategories.definitions.values.map((cat) {
        final isSelected = selectedCategory == cat.key;

        return ChoiceChip(
          label: Text(cat.key),
          avatar: Icon(
            cat.icon,
            size: 16,
            color: isSelected ? Colors.white : cat.color,
          ),
          selected: isSelected,
          selectedColor: cat.color,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : null,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusChip),
            side: BorderSide(color: isSelected ? cat.color : borderColor),
          ),
          onSelected: (selected) {
            if (selected) {
              onSelected(cat.key);
            }
          },
        );
      }).toList(),
    );
  }
}
