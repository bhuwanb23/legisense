import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum RiskLevel { low, medium, high }

class InsightRichCard extends StatelessWidget {
  const InsightRichCard({super.key, required this.icon, required this.title, required this.description, required this.level, this.iconBgColor, this.iconColor});

  final IconData icon;
  final String title;
  final String description;
  final RiskLevel level;
  final Color? iconBgColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final badge = _badgeFromLevel(level);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)), // gray-200
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: iconBgColor ?? const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, size: 16, color: iconColor ?? const Color(0xFF16A34A)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: badge.bg, borderRadius: BorderRadius.circular(9999)),
                child: Text(
                  badge.label,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: badge.fg),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.inter(fontSize: 12, height: 1.6, color: const Color(0xFF4B5563)),
          ),
        ],
      ),
    );
  }

  _Badge _badgeFromLevel(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return const _Badge('Low Risk', Color(0xFF065F46), Color(0xFFD1FAE5));
      case RiskLevel.medium:
        return const _Badge('Medium Risk', Color(0xFF92400E), Color(0xFFFEF3C7));
      case RiskLevel.high:
        return const _Badge('High Risk', Color(0xFF991B1B), Color(0xFFFEE2E2));
    }
  }
}

class _Badge {
  const _Badge(this.label, this.fg, this.bg);
  final String label;
  final Color fg;
  final Color bg;
}


