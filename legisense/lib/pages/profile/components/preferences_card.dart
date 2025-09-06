import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class PreferencesCard extends StatefulWidget {
  final bool emailNotifications;
  final bool pushNotifications;
  final String language;
  final Function(bool)? onEmailNotificationsChanged;
  final Function(bool)? onPushNotificationsChanged;
  final Function(String)? onLanguageChanged;

  const PreferencesCard({
    super.key,
    required this.emailNotifications,
    required this.pushNotifications,
    required this.language,
    this.onEmailNotificationsChanged,
    this.onPushNotificationsChanged,
    this.onLanguageChanged,
  });

  @override
  State<PreferencesCard> createState() => _PreferencesCardState();
}

class _PreferencesCardState extends State<PreferencesCard> {
  late bool _emailNotifications;
  late bool _pushNotifications;
  late String _language;

  @override
  void initState() {
    super.initState();
    _emailNotifications = widget.emailNotifications;
    _pushNotifications = widget.pushNotifications;
    _language = widget.language;
  }

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
              'Preferences',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              children: [
                // Email Notifications Toggle
                _buildToggleRow(
                  label: 'Email Notifications',
                  value: _emailNotifications,
                  onChanged: (value) {
                    setState(() {
                      _emailNotifications = value;
                    });
                    widget.onEmailNotificationsChanged?.call(value);
                  },
                ),
                
                const SizedBox(height: AppTheme.spacingM),
                
                // Push Notifications Toggle
                _buildToggleRow(
                  label: 'Push Notifications',
                  value: _pushNotifications,
                  onChanged: (value) {
                    setState(() {
                      _pushNotifications = value;
                    });
                    widget.onPushNotificationsChanged?.call(value);
                  },
                ),
                
                const SizedBox(height: AppTheme.spacingM),
                
                // Language Dropdown
                _buildLanguageDropdown(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
        GestureDetector(
          onTap: () => onChanged(!value),
          child: Container(
            width: 48,
            height: 24,
            decoration: BoxDecoration(
              color: value ? AppTheme.primaryBlue : AppTheme.borderLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Language',
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXS),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppTheme.borderLight,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _language,
              isExpanded: true,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textPrimary,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'English (US)',
                  child: Text('English (US)'),
                ),
                DropdownMenuItem(
                  value: 'Spanish',
                  child: Text('Spanish'),
                ),
                DropdownMenuItem(
                  value: 'French',
                  child: Text('French'),
                ),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _language = newValue;
                  });
                  widget.onLanguageChanged?.call(newValue);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
