import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/bottom_nav_bar.dart';
import '../../main.dart' show navigateToPage;
import 'components/components.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String filter = 'all';

  @override
  Widget build(BuildContext context) {
    final List<AppNotificationItem> items = [
      const AppNotificationItem(title: 'Document parsed successfully', description: 'Your recent upload is ready for review.', time: '2m ago', icon: Icons.check_circle, color: Color(0xFF10B981)),
      const AppNotificationItem(title: 'High-risk clause detected', description: 'Clause 4.2 may require attention.', time: '1h ago', icon: Icons.warning_amber_rounded, color: Color(0xFFF59E0B)),
      const AppNotificationItem(title: 'New policy update available', description: 'Review new compliance checklist.', time: 'Yesterday', icon: Icons.system_update_alt, color: Color(0xFF2563EB)),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        top: true,
        bottom: false,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 0,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              color: const Color(0xFF111827),
                              onPressed: () => Navigator.of(context).maybePop(),
                              tooltip: 'Back',
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Notifications',
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF111827),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Filters on their own line to avoid overflow on small screens
                        NotificationFilters(
                          active: filter,
                          onChanged: (v) => setState(() => filter = v),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 75), // leave room for bottom nav
                      child: NotificationsList(items: items),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomNavBar(
                currentIndex: 0,
                onTap: (idx) {
                  navigateToPage(idx);
                  Navigator.of(context).maybePop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


