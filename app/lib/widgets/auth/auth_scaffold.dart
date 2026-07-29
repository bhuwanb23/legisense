import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.body,
    this.title,
    this.subtitle,
    this.showBack = true,
    this.trailing,
    this.footer,
    this.hero,
  });

  final Widget body;
  final String? title;
  final String? subtitle;
  final bool showBack;
  final Widget? trailing;
  final Widget? footer;
  final Widget? hero;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
              child: Row(
                children: [
                  if (showBack)
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded, size: 22),
                      color: AppColors.ink,
                    )
                  else
                    const SizedBox(width: 48),
                  const Spacer(),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    if (hero != null) ...[
                      Center(child: hero!),
                      const SizedBox(height: 28),
                    ],
                    if (title != null || subtitle != null)
                      _Header(title: title, subtitle: subtitle),
                    body,
                    if (footer != null) ...[
                      const SizedBox(height: 24),
                      footer!,
                    ],
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.title, this.subtitle});

  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(
              title!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                height: 1.15,
                color: AppColors.ink,
              ),
            ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.45,
                color: AppColors.mute,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
