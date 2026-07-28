import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/dashboard_mock.dart';
import '../../theme/app_theme.dart';

/// Horizontal pill-shaped document type filters — matches the Dribbble
/// smart-home filter pattern (All, Living room, Kitchen, etc.).
class DocTypeFilters extends StatelessWidget {
  const DocTypeFilters({
    super.key,
    required this.selectedId,
    required this.onSelected,
  });

  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: DashboardMock.filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final filter = DashboardMock.filters[index];
          final selected = filter.id == selectedId;
          return _FilterPill(
            filter: filter,
            selected: selected,
            onTap: () => onSelected(filter.id),
          );
        },
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  final DocTypeFilter filter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryNavy : AppColors.cloud,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: selected
              ? null
              : Border.all(
                  color: AppColors.borderMuted.withValues(alpha: 0.7),
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              filter.icon,
              size: 16,
              color: selected ? AppColors.cloud : AppColors.primaryNavy,
            ),
            const SizedBox(width: 8),
            Text(
              filter.label,
              style: GoogleFonts.epilogue(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.cloud : AppColors.primaryNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
