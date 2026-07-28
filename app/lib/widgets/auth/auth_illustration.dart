import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Abstract illustration placeholders for auth pages — matches the Dribbble
/// inspiration style with soft shapes and brand colors.
/// Replace with actual SVG assets when available.
class AuthIllustration extends StatelessWidget {
  const AuthIllustration({
    super.key,
    required this.type,
    this.size = 160,
  });

  final AuthIllustrationType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _IllustrationPainter(type),
      ),
    );
  }
}

enum AuthIllustrationType { login, register, forgotPassword, otp, resetPassword, profile }

class _IllustrationPainter extends CustomPainter {
  _IllustrationPainter(this.type);

  final AuthIllustrationType type;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Background circle
    final bgPaint = Paint()
      ..color = AppColors.accentSoft.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.width * 0.42, bgPaint);

    // Decorative dots
    final dotPaint = Paint()
      ..color = AppColors.accentSky.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.25),
      4,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.3),
      3,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.15),
      5,
      dotPaint,
    );

    // Plus signs
    final plusPaint = Paint()
      ..color = AppColors.brightBlue.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    _drawPlus(canvas, Offset(size.width * 0.2, size.height * 0.7), 6, plusPaint);
    _drawPlus(canvas, Offset(size.width * 0.8, size.height * 0.65), 5, plusPaint);

    // Main icon based on type
    _drawMainIcon(canvas, size, type);
  }

  void _drawMainIcon(Canvas canvas, Size size, AuthIllustrationType type) {
    final iconPaint = Paint()
      ..color = AppColors.primaryNavy
      ..style = PaintingStyle.fill;

    final accentPaint = Paint()
      ..color = AppColors.brightBlue
      ..style = PaintingStyle.fill;

    final yellowPaint = Paint()
      ..color = const Color(0xFFF5C542)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw person silhouette (head)
    canvas.drawCircle(
      Offset(center.dx, center.dy - 12),
      18,
      iconPaint,
    );

    // Draw body (arc)
    final bodyPath = Path()
      ..moveTo(center.dx - 22, center.dy + 8)
      ..quadraticBezierTo(center.dx, center.dy + 35, center.dx + 22, center.dy + 8)
      ..close();
    canvas.drawPath(bodyPath, iconPaint);

    // Type-specific accent elements
    switch (type) {
      case AuthIllustrationType.login:
        // Chart bars
        final barPaint = Paint()..style = PaintingStyle.fill;
        barPaint.color = AppColors.brightBlue;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(center.dx - 20, center.dy + 15, 8, 20),
            const Radius.circular(2),
          ),
          barPaint,
        );
        barPaint.color = AppColors.accentSky;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(center.dx - 8, center.dy + 10, 8, 25),
            const Radius.circular(2),
          ),
          barPaint,
        );
        barPaint.color = AppColors.primaryNavy;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(center.dx + 4, center.dy + 5, 8, 30),
            const Radius.circular(2),
          ),
          barPaint,
        );
        break;

      case AuthIllustrationType.register:
        // Floating icons (camera, share, settings)
        canvas.drawCircle(Offset(center.dx - 28, center.dy - 20), 8, yellowPaint);
        canvas.drawCircle(Offset(center.dx + 28, center.dy - 15), 7, accentPaint);
        canvas.drawCircle(Offset(center.dx + 20, center.dy + 25), 6, yellowPaint);
        break;

      case AuthIllustrationType.forgotPassword:
        // Laptop shape
        final laptopPaint = Paint()
          ..color = AppColors.accentSky
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(center.dx - 18, center.dy + 10, 36, 22),
            const Radius.circular(3),
          ),
          laptopPaint,
        );
        break;

      case AuthIllustrationType.otp:
        // Lock shape
        final lockPaint = Paint()
          ..color = AppColors.brightBlue
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(center.dx - 10, center.dy + 5, 20, 16),
            const Radius.circular(4),
          ),
          lockPaint,
        );
        break;

      case AuthIllustrationType.resetPassword:
        // Shield shape
        final shieldPaint = Paint()
          ..color = AppColors.brightBlue
          ..style = PaintingStyle.fill;
        final shieldPath = Path()
          ..moveTo(center.dx, center.dy + 30)
          ..lineTo(center.dx - 16, center.dy + 15)
          ..lineTo(center.dx - 16, center.dy)
          ..quadraticBezierTo(center.dx, center.dy - 8, center.dx + 16, center.dy)
          ..lineTo(center.dx + 16, center.dy + 15)
          ..close();
        canvas.drawPath(shieldPath, shieldPaint);
        break;

      case AuthIllustrationType.profile:
        // Settings gear hint
        canvas.drawCircle(Offset(center.dx + 25, center.dy - 25), 8, yellowPaint);
        break;
    }
  }

  void _drawPlus(Canvas canvas, Offset center, double armLength, Paint paint) {
    canvas.drawLine(
      Offset(center.dx - armLength, center.dy),
      Offset(center.dx + armLength, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - armLength),
      Offset(center.dx, center.dy + armLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _IllustrationPainter oldDelegate) =>
      type != oldDelegate.type;
}
