import 'package:flutter/material.dart';

import '../../widgets/home/stub_scaffold.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const StubScaffold(
      title: 'Notifications',
      subtitle: 'Deadline reminders and analysis updates will appear here.',
    );
  }
}
