import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

/// Shared page header for main tabs — TripGlide Operate theme.
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 0),
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final EdgeInsetsGeometry padding;

  /// Greeting + avatar pattern used on Home.
  factory AppPageHeader.greeting({
    Key? key,
    required String name,
    String subtitle = 'Welcome to Legisense',
    Widget? trailing,
    EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(20, 12, 20, 0),
  }) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'L';
    return AppPageHeader(
      key: key,
      title: 'Hello, $name',
      subtitle: subtitle,
      padding: padding,
      trailing: trailing ??
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.chip,
              shape: BoxShape.circle,
              boxShadow: AppShadows.soft,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    color: AppColors.ink,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.mute,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Circular surface action used next to [AppPageHeader].
class AppHeaderIconButton extends StatelessWidget {
  const AppHeaderIconButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: AppShadows.soft,
          ),
          child: Icon(icon, size: 18, color: AppColors.ink),
        ),
      ),
    );
  }
}
