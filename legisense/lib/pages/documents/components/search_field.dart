import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchField extends StatelessWidget {
  const SearchField({super.key, this.onChanged});

  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: _AnimatedFocusField(onChanged: onChanged),
    );
  }
}

class _AnimatedFocusField extends StatefulWidget {
  const _AnimatedFocusField({this.onChanged});
  final ValueChanged<String>? onChanged;

  @override
  State<_AnimatedFocusField> createState() => _AnimatedFocusFieldState();
}

class _AnimatedFocusFieldState extends State<_AnimatedFocusField> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _focused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        boxShadow: _focused
            ? [BoxShadow(color: const Color(0xFF60A5FA).withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))]
            : null,
      ),
      child: TextField(
        focusNode: _focusNode,
        onChanged: widget.onChanged,
        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF111827)),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF9CA3AF)),
          hintText: 'Search documents...',
          hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF9CA3AF)),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF93C5FD)),
          ),
        ),
      ),
    );
  }
}


