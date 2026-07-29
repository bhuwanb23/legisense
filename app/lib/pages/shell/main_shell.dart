import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/home/app_bottom_nav.dart';
import '../documents/documents_page.dart';
import '../home/home_page.dart';
import '../notifications/notifications_page.dart';
import '../profile/profile_page.dart';
import '../upload/upload_page.dart';

/// Post-auth root — floating TripGlide dock.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;

  void goToTab(int index) {
    if (index < 0 || index > 4) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: [
          HomePage(
            onOpenUpload: () => goToTab(2),
            onOpenDocuments: () => goToTab(1),
            onOpenNotifications: () => goToTab(3),
          ),
          DocumentsPage(onOpenUpload: () => goToTab(2)),
          const UploadPage(),
          const NotificationsPage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onChanged: goToTab,
      ),
    );
  }
}
