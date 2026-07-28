import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

/// Clean icon field matching the Dribbble inspiration — placeholder text,
/// leading icon, subtle border, no label above.
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.icon,
    this.controller,
    this.hint,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.autofillHints,
    this.enabled = true,
    this.trailing,
  });

  final String label;
  final IconData icon;
  final TextEditingController? controller;
  final String? hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;
  final bool enabled;
  final Widget? trailing;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _obscured = widget.obscureText;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: TextFormField(
        controller: widget.controller,
        enabled: widget.enabled,
        obscureText: _obscured,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        autofillHints: widget.autofillHints,
        validator: widget.validator,
        onChanged: widget.onChanged,
        style: GoogleFonts.epilogue(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.primaryNavy,
          height: 1.2,
        ),
        decoration: InputDecoration(
          hintText: widget.hint ?? widget.label,
          hintStyle: GoogleFonts.epilogue(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.inkSoft.withValues(alpha: 0.5),
          ),
          filled: true,
          fillColor: AppColors.cloud,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(
              widget.icon,
              size: 20,
              color: _focused
                  ? AppColors.primaryNavy
                  : AppColors.inkSoft.withValues(alpha: 0.5),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
          suffixIcon: widget.trailing ??
              (widget.obscureText
                  ? IconButton(
                      onPressed: () =>
                          setState(() => _obscured = !_obscured),
                      icon: Icon(
                        _obscured
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.inkSoft.withValues(alpha: 0.5),
                        size: 20,
                      ),
                    )
                  : null),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.field),
            borderSide: BorderSide(
              color: AppColors.borderMuted.withValues(alpha: 0.6),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.field),
            borderSide: BorderSide(
              color: AppColors.borderMuted.withValues(alpha: 0.6),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.field),
            borderSide: const BorderSide(
              color: AppColors.primaryNavy,
              width: 1.4,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.field),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.field),
            borderSide: const BorderSide(color: AppColors.error, width: 1.4),
          ),
        ),
      ),
    );
  }
}
