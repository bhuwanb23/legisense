import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RiskFlagItem {
  const RiskFlagItem({required this.text, required this.level, required this.why});
  final String text; // message
  final String level; // 'low' | 'medium' | 'high'
  final String why; // tooltip content
}

class RiskFlagsList extends StatelessWidget {
  const RiskFlagsList({super.key, required this.items});
  final List<RiskFlagItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(items.length, (index) {
        final item = items[index];
        final color = item.level == 'high'
            ? const Color(0xFFDC2626)
            : item.level == 'medium'
                ? const Color(0xFFCA8A04)
                : const Color(0xFF16A34A);
        final bg = item.level == 'high'
            ? const Color(0xFFFEE2E2)
            : item.level == 'medium'
                ? const Color(0xFFFEF3C7)
                : const Color(0xFFD1FAE5);
        final icon = item.level == 'high'
            ? Icons.error_rounded
            : item.level == 'medium'
                ? Icons.report_problem_rounded
                : Icons.info_rounded;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.98, end: 1),
          duration: Duration(milliseconds: 200 + index * 60),
          curve: Curves.easeOut,
          builder: (context, value, child) => Transform.scale(scale: value, child: child),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: bg.withValues(alpha: 0.8)),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.text,
                    style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
                  ),
                ),
                Tooltip(
                  message: item.why,
                  triggerMode: TooltipTriggerMode.tap,
                  preferBelow: false,
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                  textStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white),
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text('Why?', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}


