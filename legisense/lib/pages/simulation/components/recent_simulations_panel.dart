import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RecentSimulationsPanel extends StatelessWidget {
  const RecentSimulationsPanel({super.key, required this.items, this.onOpen});

  final List<RecentSimItem> items;
  final void Function(RecentSimItem item)? onOpen;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Simulations', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ...items.take(3).map((e) => _tile(e)).toList(),
      ],
    );
  }

  Widget _tile(RecentSimItem e) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      leading: const Icon(Icons.timeline, color: Color(0xFF2563EB)),
      title: Text(e.title, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      subtitle: Text('${e.type} • ${e.timeAgo}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF9CA3AF)),
      onTap: onOpen == null ? null : () => onOpen!(e),
    );
  }
}

class RecentSimItem {
  const RecentSimItem({required this.title, required this.type, required this.timeAgo});
  final String title;
  final String type;
  final String timeAgo;
}


