import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Floating black pill dock — TripGlide DNA.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _DockItem(
                icon: Icons.home_rounded,
                selected: currentIndex == 0,
                onTap: () => onChanged(0),
              ),
              _DockItem(
                icon: Icons.folder_rounded,
                selected: currentIndex == 1,
                onTap: () => onChanged(1),
              ),
              _DockItem(
                icon: Icons.add_rounded,
                selected: currentIndex == 2,
                onTap: () => onChanged(2),
              ),
              _DockItem(
                icon: Icons.notifications_rounded,
                selected: currentIndex == 3,
                onTap: () => onChanged(3),
              ),
              _DockItem(
                icon: Icons.grid_view_rounded,
                selected: currentIndex == 4,
                onTap: () => onChanged(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 22,
          color: selected ? AppColors.ink : AppColors.surface.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}

/// Legacy label finder helpers for tests — dock is icon-only.
String dockSemanticsLabel(int index) => switch (index) {
      0 => 'Home',
      1 => 'Documents',
      2 => 'Upload',
      3 => 'Notify',
      4 => 'Profile',
      _ => 'Tab',
    };
