import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.field),
            boxShadow: AppShadows.soft,
          ),
          child: TextFormField(
            controller: widget.controller,
            enabled: widget.enabled,
            obscureText: _obscured,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            autofillHints: widget.autofillHints,
            validator: widget.validator,
            onChanged: widget.onChanged,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
            decoration: InputDecoration(
              hintText: widget.hint ?? widget.label,
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.mute.withValues(alpha: 0.7),
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              prefixIcon: Icon(widget.icon, size: 20, color: AppColors.mute),
              suffixIcon: widget.trailing ??
                  (widget.obscureText
                      ? IconButton(
                          onPressed: () =>
                              setState(() => _obscured = !_obscured),
                          icon: Icon(
                            _obscured
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.mute,
                            size: 20,
                          ),
                        )
                      : null),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.field),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.field),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.field),
                borderSide: const BorderSide(color: AppColors.ink, width: 1.4),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.field),
                borderSide: const BorderSide(color: AppColors.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.field),
                borderSide:
                    const BorderSide(color: AppColors.error, width: 1.4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
