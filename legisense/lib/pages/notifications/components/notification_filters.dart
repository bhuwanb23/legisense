import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationFilters extends StatelessWidget {
  const NotificationFilters({super.key, required this.onChanged, required this.active});

  final ValueChanged<String> onChanged;
  final String active;

  Widget _chip(String label, String value) {
    final bool selected = value == active;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        label: Text(label, style: GoogleFonts.inter(fontSize: 12)),
        onSelected: (_) => onChanged(value),
        selectedColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
        backgroundColor: const Color(0xFFF3F4F6),
        checkmarkColor: const Color(0xFF2563EB),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 340;
        final chips = [
          _chip('All', 'all'),
          _chip('Updates', 'updates'),
          _chip('Warnings', 'warnings'),
          _chip('System', 'system'),
        ];
        if (isNarrow) {
          return Wrap(spacing: 8, runSpacing: 8, children: chips);
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: chips),
        );
      },
    );
  }
}


