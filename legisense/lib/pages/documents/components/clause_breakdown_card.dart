import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../profile/language/language_scope.dart';
import '../language/strings.dart';

enum ClauseRisk { low, medium, high }

class ClauseBreakdownCard extends StatelessWidget {
  const ClauseBreakdownCard({
    super.key,
    required this.title,
    required this.icon,
    required this.originalSnippet,
    required this.explanation,
    required this.risk,
  });

  final String title;
  final IconData icon;
  final String originalSnippet;
  final String explanation;
  final ClauseRisk risk;

  Color get riskColor => switch (risk) {
        ClauseRisk.low => const Color(0xFF16A34A),
        ClauseRisk.medium => const Color(0xFFCA8A04),
        ClauseRisk.high => const Color(0xFFDC2626),
      };

  Color get riskBg => switch (risk) {
        ClauseRisk.low => const Color(0xFFD1FAE5),
        ClauseRisk.medium => const Color(0xFFFEF3C7),
        ClauseRisk.high => const Color(0xFFFEE2E2),
      };

  String get riskLabel => switch (risk) {
        ClauseRisk.low => 'Low',
        ClauseRisk.medium => 'Medium',
        ClauseRisk.high => 'High',
      };

  String _getRiskLabel(BuildContext context, ClauseRisk risk) {
    final globalLanguage = LanguageScope.of(context).language;
    final i18n = DocumentsI18n.mapFor(globalLanguage);
    
    switch (risk) {
      case ClauseRisk.low:
        return i18n['analysis.risk.low'] ?? 'Low';
      case ClauseRisk.medium:
        return i18n['analysis.risk.medium'] ?? 'Medium';
      case ClauseRisk.high:
        return i18n['analysis.risk.high'] ?? 'High';
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, 8),
              blurRadius: 24,
            ),
          ],
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(color: riskBg, borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.all(8),
                  child: Icon(icon, color: riskColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(color: riskBg, borderRadius: BorderRadius.circular(999)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    '${DocumentsI18n.mapFor(LanguageScope.of(context).language)['analysis.risk.label'] ?? 'Risk'}: ${_getRiskLabel(context, risk)}',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: riskColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote, color: Color(0xFF64748B), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      originalSnippet,
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155), height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(DocumentsI18n.mapFor(LanguageScope.of(context).language)['analysis.simple.terms'] ?? 'In simple terms', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              explanation,
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}


