import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../theme/app_theme.dart';

class PersonalInfoCard extends StatefulWidget {
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
  State<PersonalInfoCard> createState() => _PersonalInfoCardState();
}

class _PersonalInfoCardState extends State<PersonalInfoCard> {
  bool _pressed = false;

  void _setPressed(bool v) => setState(() => _pressed = v);

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..translate(0.0, _pressed ? -1.5 : 0.0),
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: AppTheme.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _pressed ? 0.08 : 0.05),
            blurRadius: _pressed ? 10 : 4,
            offset: const Offset(0, 4),
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
                  value: widget.fullName,
                  icon: FontAwesomeIcons.user,
                  onChanged: widget.onNameChanged,
                ),
                const SizedBox(height: AppTheme.spacingM),
                _buildFormField(
                  label: 'Phone Number',
                  value: widget.phoneNumber,
                  icon: FontAwesomeIcons.phone,
                  onChanged: widget.onPhoneChanged,
                ),
                const SizedBox(height: AppTheme.spacingM),
                _buildFormField(
                  label: 'Location',
                  value: widget.location,
                  icon: FontAwesomeIcons.locationDot,
                  onChanged: widget.onLocationChanged,
                ),
              ],
            ),
          ),
        ],
      ),
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
