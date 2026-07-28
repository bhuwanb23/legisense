import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/dashboard_mock.dart';
import '../../theme/app_theme.dart';

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
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: DashboardMock.filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final filter = DashboardMock.filters[index];
          final selected = filter.id == selectedId;
          return _FilterDisc(
            filter: filter,
            selected: selected,
            onTap: () => onSelected(filter.id),
          );
        },
      ),
    );
  }
}

class _FilterDisc extends StatelessWidget {
  const _FilterDisc({
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
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.primaryNavy : AppColors.cloud,
                border: selected
                    ? null
                    : Border.all(color: AppColors.borderMuted),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryNavy.withValues(
                      alpha: selected ? 0.2 : 0.06,
                    ),
                    blurRadius: selected ? 14 : 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                filter.icon,
                size: 22,
                color: selected ? AppColors.cloud : AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              filter.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.epilogue(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.primaryNavy : AppColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
