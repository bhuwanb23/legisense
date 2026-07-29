import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/analysis_mock.dart';
import '../../data/dashboard_mock.dart';
import '../../data/notifications_mock.dart';
import '../../theme/app_theme.dart';
import '../../widgets/home/stub_scaffold.dart';
import '../analysis/analysis_results_page.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  void _open(BuildContext context, AppNotification n) {
    if (n.docId != null) {
      MockDocument? doc;
      for (final d in DashboardMock.recentDocuments) {
        if (d.id == n.docId) {
          doc = d;
          break;
        }
      }
      if (doc != null) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AnalysisResultsPage(
              result: AnalysisResult.fromMockDocument(doc!),
            ),
          ),
        );
        return;
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(n.body),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  IconData _icon(NotificationType type) => switch (type) {
        NotificationType.deadline => Icons.event_outlined,
        NotificationType.analysisReady => Icons.fact_check_outlined,
        NotificationType.tip => Icons.lightbulb_outline_rounded,
      };

  Color _tint(NotificationType type) => switch (type) {
        NotificationType.deadline => AppColors.riskMedium,
        NotificationType.analysisReady => AppColors.ink,
        NotificationType.tip => AppColors.accentGold,
      };

  @override
  Widget build(BuildContext context) {
    final items = NotificationsMock.items;

    return StubScaffold(
      title: 'Alerts',
      subtitle: 'Deadlines, analysis updates, and counsel tips.',
      child: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final n = items[i];
          final tint = _tint(n.type);
          return Material(
            color: AppColors.cloud,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.md),
              onTap: () => _open(context, n),
              child: Ink(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: AppColors.rule),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: tint.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_icon(n.type), color: tint, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  n.title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              if (n.unread)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accentGold,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            n.body,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              height: 1.4,
                              color: AppColors.inkSoft,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            n.timeLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.inkSoft.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
