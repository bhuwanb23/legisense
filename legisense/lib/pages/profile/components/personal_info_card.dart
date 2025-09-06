import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../theme/app_theme.dart';

class PersonalInfoCard extends StatelessWidget {
  final String fullName;
  final String phoneNumber;
  final String location;
  final Function(String)? onNameChanged;
  final Function(String)? onPhoneChanged;
  final Function(String)? onLocationChanged;

  const PersonalInfoCard({
    super.key,
    required this.fullName,
    required this.phoneNumber,
    required this.location,
    this.onNameChanged,
    this.onPhoneChanged,
    this.onLocationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: AppTheme.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingS,
            ),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.borderLight,
                  width: 1,
                ),
              ),
            ),
            child: Text(
              'Personal Info',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          // Form fields
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              children: [
                _buildFormField(
                  label: 'Full Name',
                  value: fullName,
                  icon: FontAwesomeIcons.user,
                  onChanged: onNameChanged,
                ),
                const SizedBox(height: AppTheme.spacingM),
                _buildFormField(
                  label: 'Phone Number',
                  value: phoneNumber,
                  icon: FontAwesomeIcons.phone,
                  onChanged: onPhoneChanged,
                ),
                const SizedBox(height: AppTheme.spacingM),
                _buildFormField(
                  label: 'Location',
                  value: location,
                  icon: FontAwesomeIcons.locationDot,
                  onChanged: onLocationChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required String value,
    required IconData icon,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXS),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textPrimary,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              size: 16,
              color: AppTheme.textSecondary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
              borderSide: const BorderSide(
                color: AppTheme.borderLight,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
              borderSide: const BorderSide(
                color: AppTheme.borderLight,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
              borderSide: const BorderSide(
                color: AppTheme.primaryBlue,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingS,
            ),
          ),
        ),
      ],
    );
  }
}
