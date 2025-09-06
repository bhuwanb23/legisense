import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_theme.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final List<InfoField> fields;
  final VoidCallback? onEdit;
  final int delay;

  const InfoCard({
    super.key,
    required this.title,
    required this.fields,
    this.onEdit,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: AppTheme.spacingM),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusL),
                topRight: Radius.circular(AppTheme.radiusL),
              ),
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: AppTheme.heading4.copyWith(
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const Spacer(),
                if (onEdit != null)
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onEdit,
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        child: const Padding(
                          padding: EdgeInsets.all(AppTheme.spacingS),
                          child: Icon(
                            FontAwesomeIcons.penToSquare,
                            color: AppTheme.primaryBlue,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: fields.asMap().entries.map((entry) {
                final index = entry.key;
                final field = entry.value;
                return Column(
                  children: [
                    _buildField(field, index),
                    if (index < fields.length - 1)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
                        height: 1,
                        color: AppTheme.borderLight,
                      ),
                  ],
                );
              }).toList(),
            ),
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
        .fadeIn(duration: AppTheme.animationSlow, delay: delay.ms);
  }

  Widget _buildField(InfoField field, int index) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: AppTheme.iconContainerSmallDecoration,
          child: Icon(
            field.icon,
            color: AppTheme.primaryBlue,
            size: 16,
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                field.label,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXS),
              if (field.isEditable)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.borderLight,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  ),
                  child: TextFormField(
                    initialValue: field.value,
                    style: AppTheme.bodyLarge,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingM,
                        vertical: AppTheme.spacingM,
                      ),
                      hintText: field.hint,
                      hintStyle: AppTheme.bodyLarge.copyWith(
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ),
                )
              else
                Text(
                  field.value,
                  style: AppTheme.bodyLarge,
                ),
            ],
          ),
        ),
      ],
    )
        .animate()
        .slideX(
          begin: 0.2,
          duration: AppTheme.animationFast,
          curve: Curves.easeOut,
        )
        .fadeIn(duration: AppTheme.animationMedium, delay: (delay + 200 + (index * 100)).ms);
  }
}

class InfoField {
  final IconData icon;
  final String label;
  final String value;
  final String? hint;
  final bool isEditable;

  InfoField({
    required this.icon,
    required this.label,
    required this.value,
    this.hint,
    this.isEditable = false,
  });
}
