import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_theme.dart';

class UserInfoSection extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final VoidCallback? onEdit;

  const UserInfoSection({
    super.key,
    required this.name,
    required this.email,
    required this.role,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTheme.heading1.copyWith(
                        color: AppTheme.primaryBlueDark,
                      ),
                    )
                        .animate()
                        .slideY(
                          begin: 0.3,
                          duration: AppTheme.animationMedium,
                          curve: Curves.easeOut,
                        )
                        .fadeIn(duration: AppTheme.animationSlow, delay: 200.ms),
                    const SizedBox(height: AppTheme.spacingS),
                    Row(
                      children: [
                        const Icon(
                          FontAwesomeIcons.envelope,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        Text(
                          email,
                          style: AppTheme.bodyLarge.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    )
                        .animate()
                        .slideY(
                          begin: 0.3,
                          duration: AppTheme.animationMedium,
                          curve: Curves.easeOut,
                        )
                        .fadeIn(duration: AppTheme.animationSlow, delay: 400.ms),
                    const SizedBox(height: AppTheme.spacingS),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingM,
                        vertical: AppTheme.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        role,
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          duration: AppTheme.animationMedium,
                          curve: Curves.elasticOut,
                        )
                        .fadeIn(duration: AppTheme.animationSlow, delay: 600.ms),
                  ],
                ),
              ),
              if (onEdit != null)
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onEdit,
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      child: const Padding(
                        padding: EdgeInsets.all(AppTheme.spacingM),
                        child: Icon(
                          FontAwesomeIcons.penToSquare,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      duration: AppTheme.animationMedium,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: AppTheme.animationSlow, delay: 800.ms),
            ],
          ),
        ],
      ),
    )
        .animate()
        .slideY(
          begin: 0.3,
          duration: AppTheme.animationMedium,
          curve: Curves.easeOut,
        )
        .fadeIn(duration: AppTheme.animationSlow, delay: 400.ms);
  }
}
