import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../profile/language/language_scope.dart';
import '../language/strings.dart';

class DetailTabs extends StatelessWidget {
  const DetailTabs({super.key, required this.index, required this.onChange});

  final int index;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
        color: Colors.white,
      ),
      child: Row(
        children: [
          _tab(_label(context, 'docs.tab.text', fallback: 'Text'), 0),
          _tab(_label(context, 'docs.tab.analysis', fallback: 'Analysis'), 1),
        ],
      ),
    );
  }

  Expanded _tab(String label, int value) {
    final bool selected = index == value;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChange(value),
          child: Container(
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? const Color(0xFF2563EB) : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected ? const Color(0xFF2563EB) : const Color(0xFF6B7280),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _label(BuildContext context, String key, {required String fallback}) {
  final lang = LanguageScope.maybeOf(context)?.language ?? AppLanguage.en;
  final i18n = DocumentsI18n.mapFor(lang);
  return i18n[key] ?? fallback;
}


