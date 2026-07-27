import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import 'skeleton_loader.dart';

class ActivityTimeline extends StatelessWidget {
  const ActivityTimeline({super.key, this.activities = const [], this.isLoading = false});

  final List<TimelineActivity> activities;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _TimelineSkeleton();
    }

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
                Icon(Icons.timeline, color: AppTheme.primaryBlue, size: 18),
                SizedBox(width: 8),
                Text('Recent Activity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
              ],
            ),
            const SizedBox(height: 12),
            ...activities.map((a) => _TimelineItem(activity: a)),
          ],
        ),
      ),
    );
  }
}

class TimelineActivity {
  final IconData icon;
  final String title;
  final String timeAgo;
  final Color color;

  TimelineActivity({
    required this.icon,
    required this.title,
    required this.timeAgo,
    this.color = AppTheme.primaryBlue,
  });
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.activity});

  final TimelineActivity activity;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: activity.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(activity.icon, size: 16, color: activity.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                const SizedBox(height: 2),
                Text(activity.timeAgo, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineSkeleton extends StatelessWidget {
  const _TimelineSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonLine(width: 120, height: 14),
            const SizedBox(height: 12),
            ...List.generate(3, (i) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SkeletonBox(size: 28),
                  SizedBox(width: 10),
                  Expanded(child: SkeletonLine(height: 13)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}


