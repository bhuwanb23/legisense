import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class ProfileStats extends StatelessWidget {
  const ProfileStats({super.key, this.stats = const []});

  final List<StatItem> stats;

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Row(
          children: stats.map((s) => Expanded(child: _StatTile(item: s))).toList(),
        ),
      ),
    );
  }
}

class StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StatItem({required this.label, required this.value, required this.icon, this.color = AppTheme.primaryBlue});
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.item});

  final StatItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(item.icon, color: item.color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(item.value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        const SizedBox(height: 2),
        Text(item.label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
      ],
    );
  }
}


