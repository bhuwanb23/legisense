import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

/// TripGlide search pill + black filter disc.
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({
    super.key,
    required this.onSearch,
    required this.onFilter,
    this.hint = 'Search documents',
  });

  final VoidCallback onSearch;
  final VoidCallback onFilter;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onSearch,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                boxShadow: AppShadows.soft,
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppColors.mute, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    hint,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppColors.mute,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: AppColors.ink,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onFilter,
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.tune_rounded, color: AppColors.surface, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}
