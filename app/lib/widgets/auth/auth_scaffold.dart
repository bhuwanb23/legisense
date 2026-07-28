import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

/// Shared chrome for auth screens: sky gradient, blobs, optional back, scroll body.
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
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.skyWash, AppColors.skyMist, Color(0xFFEEF5FC)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -size.width * 0.15,
              right: -size.width * 0.2,
              child: _Blob(
                diameter: size.width * 0.55,
                color: AppColors.accentSoft.withValues(alpha: 0.45),
              ),
            ),
            Positioned(
              top: size.height * 0.18,
              left: -size.width * 0.25,
              child: _Blob(
                diameter: size.width * 0.5,
                color: AppColors.accentSky.withValues(alpha: 0.18),
              ),
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm,
                      AppSpacing.xs,
                      AppSpacing.screenH,
                      0,
                    ),
                    child: Row(
                      children: [
                        if (showBack)
                          IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
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
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenH,
                        AppSpacing.sm,
                        AppSpacing.screenH,
                        AppSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (hero != null) ...[
                            hero!,
                            const SizedBox(height: AppSpacing.lg),
                          ],
                          if (title != null) ...[
                            Text(
                              title!,
                              style: GoogleFonts.epilogue(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                height: 1.15,
                                letterSpacing: -0.6,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                subtitle!,
                                style: GoogleFonts.epilogue(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  height: 1.45,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.xl),
                          ],
                          body,
                        ],
                      ),
                    ),
                  ),
                  if (footer != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenH,
                        0,
                        AppSpacing.screenH,
                        AppSpacing.lg,
                      ),
                      child: footer!,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
