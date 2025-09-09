import 'package:flutter/material.dart';
import '../notification_item.dart';

class NotificationsList extends StatelessWidget {
  const NotificationsList({super.key, required this.items});

  final List<AppNotificationItem> items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => items[i],
    );
  }
}


