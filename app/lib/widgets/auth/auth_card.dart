import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Cloud surface with hairline rule — letter stack for auth forms.
class AuthCard extends StatelessWidget {
  const AuthCard({
    super.key,
    required this.child,
    this.maxWidth = 420,
    this.padding = const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
