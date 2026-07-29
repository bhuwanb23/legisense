import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.greeting,
    required this.name,
    required this.onNotifications,
    required this.onSearch,
  });

  final String greeting;
  final String name;
  final VoidCallback onNotifications;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'L';

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.accentSoft,
          child: Text(
            initial,
            style: GoogleFonts.epilogue(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryNavy,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, $name',
                style: GoogleFonts.spectral(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  letterSpacing: -0.3,
                  fontStyle: FontStyle.normal,
                ),
              ),
              Text(
                greeting,
                style: GoogleFonts.epilogue(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
        _IconBtn(
          icon: Icons.search_rounded,
          onTap: onSearch,
        ),
        const SizedBox(width: 8),
        _IconBtn(
          icon: Icons.notifications_outlined,
          onTap: onNotifications,
        ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cloud,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.borderMuted.withValues(alpha: 0.6),
            ),
          ),
          child: Icon(icon, size: 20, color: AppColors.primaryNavy),
        ),
      ),
    );
  }
}
