import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class ProfileBadges extends StatelessWidget {
  const ProfileBadges({super.key, this.badges = const []});

  final List<UserBadge> badges;

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.emoji_events, color: AppTheme.warningOrange, size: 18),
                SizedBox(width: 8),
                Text('Badges', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: badges.map((b) => _BadgeChip(badge: b)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class UserBadge {
  final String label;
  final IconData icon;
  final Color color;

  const UserBadge({required this.label, required this.icon, this.color = AppTheme.primaryBlue});
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge});

  final UserBadge badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badge.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: badge.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badge.icon, size: 14, color: badge.color),
          const SizedBox(width: 6),
          Text(badge.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: badge.color)),
        ],
      ),
    );
  }
}


