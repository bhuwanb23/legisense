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
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: DashboardMock.filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final filter = DashboardMock.filters[index];
          final selected = filter.id == selectedId;
          return GestureDetector(
            onTap: () => onSelected(filter.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: selected ? AppColors.ink : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                boxShadow: selected ? null : AppShadows.soft,
              ),
              alignment: Alignment.center,
              child: Text(
                filter.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.surface : AppColors.mute,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
