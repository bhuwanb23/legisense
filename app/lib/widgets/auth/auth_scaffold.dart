import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

/// Minimal auth chrome — soft wash, no decorative clutter.
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
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.85),
            radius: 1.15,
            colors: [
              Color(0xFFD7E9FA),
              AppColors.skyMist,
              Color(0xFFFBFCFE),
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
                child: Row(
                  children: [
                    if (showBack)
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded, size: 22),
                        color: AppColors.primaryNavy,
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
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (hero != null) ...[
                        hero!,
                        const SizedBox(height: 28),
                      ],
                      if (title != null) ...[
                        Text(
                          title!,
                          style: GoogleFonts.epilogue(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                            letterSpacing: -0.7,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            subtitle!,
                            style: GoogleFonts.epilogue(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.45,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                      ],
                      body,
                    ],
                  ),
                ),
              ),
              if (footer != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                  child: footer!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
