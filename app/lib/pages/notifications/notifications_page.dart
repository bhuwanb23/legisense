import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/analysis_mock.dart';
import '../../data/dashboard_mock.dart';
import '../../data/notifications_mock.dart';
import '../../theme/app_theme.dart';
import '../../widgets/home/app_page_header.dart';
import '../analysis/analysis_results_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String _filter = 'all'; // all | unread
  late List<AppNotification> _items =
      List<AppNotification>.from(NotificationsMock.items);

  List<AppNotification> get _visible {
    if (_filter == 'unread') {
      return _items.where((n) => n.unread).toList();
    }
    return _items;
  }

  void _markAllRead() {
    setState(() {
      _items = _items
          .map(
            (n) => AppNotification(
              id: n.id,
              type: n.type,
              title: n.title,
              body: n.body,
              timeLabel: n.timeLabel,
              group: n.group,
              docId: n.docId,
              unread: false,
            ),
          )
          .toList();
    });
  }

  void _markRead(AppNotification n) {
    setState(() {
      _items = _items
          .map(
            (x) => x.id == n.id
                ? AppNotification(
                    id: x.id,
                    type: x.type,
                    title: x.title,
                    body: x.body,
                    timeLabel: x.timeLabel,
                    group: x.group,
                    docId: x.docId,
                    unread: false,
                  )
                : x,
          )
          .toList();
    });
  }

  void _open(AppNotification n) {
    _markRead(n);
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
        content: Text(n.body, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  ({IconData icon, Color tint, Color fg}) _style(NotificationType type) {
    return switch (type) {
      NotificationType.deadline => (
          icon: Icons.event_outlined,
          tint: AppColors.riskMediumBg,
          fg: AppColors.riskMedium,
        ),
      NotificationType.analysisReady => (
          icon: Icons.fact_check_outlined,
          tint: AppColors.chip,
          fg: AppColors.ink,
        ),
      NotificationType.tip => (
          icon: Icons.lightbulb_outline_rounded,
          tint: const Color(0xFFE8F5E9),
          fg: AppColors.riskLow,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final today =
        visible.where((n) => n.group == NotificationGroup.today).toList();
    final yesterday =
        visible.where((n) => n.group == NotificationGroup.yesterday).toList();
    final earlier =
        visible.where((n) => n.group == NotificationGroup.earlier).toList();

    return ColoredBox(
      color: AppColors.bg,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(
              title: 'Notifications',
              subtitle: 'Deadlines, analysis, and tips',
              trailing: AppHeaderIconButton(
                icon: Icons.done_all_rounded,
                onTap: _markAllRead,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _filter == 'all',
                    onTap: () => setState(() => _filter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Unread',
                    selected: _filter == 'unread',
                    onTap: () => setState(() => _filter = 'unread'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _markAllRead,
                    child: Text(
                      'Mark all as read',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: visible.isEmpty
                  ? Center(
                      child: Text(
                        'No notifications',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.mute,
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 110),
                      children: [
                        if (today.isNotEmpty) ...[
                          _SectionLabel('Today'),
                          ...today.map(_card),
                        ],
                        if (yesterday.isNotEmpty) ...[
                          _SectionLabel('Yesterday'),
                          ...yesterday.map(_card),
                        ],
                        if (earlier.isNotEmpty) ...[
                          _SectionLabel('Earlier'),
                          ...earlier.map(_card),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(AppNotification n) {
    final style = _style(n.type);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: () => _open(n),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.md),
              boxShadow: AppShadows.soft,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: style.tint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(style.icon, color: style.fg, size: 22),
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
                              margin: const EdgeInsets.only(left: 6),
                              decoration: const BoxDecoration(
                                color: AppColors.ink,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        n.body,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          height: 1.4,
                          color: AppColors.mute,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        n.timeLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.mute.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          boxShadow: selected ? null : AppShadows.soft,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.surface : AppColors.mute,
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
    );
  }
}
