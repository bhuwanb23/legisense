import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppNotificationItem extends StatelessWidget {
  const AppNotificationItem({super.key, required this.title, required this.time, this.description, this.icon, this.color});

  final String title;
  final String time;
  final String? description;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color accent = color ?? const Color(0xFF2563EB);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon ?? Icons.notifications, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
                if (description != null && description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(description!, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF4B5563))),
                ],
                const SizedBox(height: 6),
                Text(time, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


