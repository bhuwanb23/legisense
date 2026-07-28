import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// White rounded card wrapper for auth pages — centers content like the
/// Dribbble inspiration with large radius and subtle shadow.
class AuthCard extends StatelessWidget {
  const AuthCard({
    super.key,
    required this.child,
    this.maxWidth = 420,
    this.padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.cloud,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryNavy.withValues(alpha: 0.06),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
