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
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 4),
                    if (hero != null) ...[
                      Center(child: hero!),
                      const SizedBox(height: 20),
                    ],
                    if (title != null || subtitle != null)
                      _Header(title: title, subtitle: subtitle),
                    body,
                    if (footer != null) ...[
                      const SizedBox(height: 20),
                      footer!,
                    ],
                    const SizedBox(height: 20),
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
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (title != null)
            Text(
              title!,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                height: 1.15,
                color: AppColors.ink,
              ),
            ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
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
