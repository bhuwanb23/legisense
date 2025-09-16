import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../language/language_scope.dart';
import '../language/strings.dart';

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
    _language = widget.language == 'English (US)'
        ? 'en'
        : (['en','hi','ta','te'].contains(widget.language) ? widget.language : 'en');
  }

  @override
  Widget build(BuildContext context) {
    final controller = LanguageScope.of(context);
    final i18n = ProfileI18n.mapFor(controller.language);
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
              i18n['preferences.title'] ?? 'Preferences',
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
                  label: i18n['preferences.email'] ?? 'Email Notifications',
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
                  label: i18n['preferences.push'] ?? 'Push Notifications',
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
                _buildLanguageDropdown(i18n, controller),
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
        Expanded(
          child: Text(
            label,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ),
        const SizedBox(width: AppTheme.spacingS),
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

  Widget _buildLanguageDropdown(Map<String, String> i18n, LanguageController controller) {
    final String dropdownValue = _normalizeLanguage(_language);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          i18n['preferences.language'] ?? 'Language',
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
              value: dropdownValue,
              isExpanded: true,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textPrimary,
              ),
              items: [
                DropdownMenuItem(
                  value: 'en',
                  child: Text(i18n['language.english'] ?? 'English'),
                ),
                DropdownMenuItem(
                  value: 'hi',
                  child: Text(i18n['language.hindi'] ?? 'Hindi'),
                ),
                DropdownMenuItem(
                  value: 'ta',
                  child: Text(i18n['language.tamil'] ?? 'Tamil'),
                ),
                DropdownMenuItem(
                  value: 'te',
                  child: Text(i18n['language.telugu'] ?? 'Telugu'),
                ),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _language = newValue;
                  });
                  widget.onLanguageChanged?.call(newValue);
                  // Propagate to global language controller
                  Future.microtask(() {
                    switch (newValue) {
                      case 'hi':
                        controller.setLanguage(AppLanguage.hi);
                        break;
                      case 'ta':
                        controller.setLanguage(AppLanguage.ta);
                        break;
                      case 'te':
                        controller.setLanguage(AppLanguage.te);
                        break;
                      case 'en':
                      default:
                        controller.setLanguage(AppLanguage.en);
                    }
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  String _normalizeLanguage(String value) {
    if (value == 'English (US)') return 'en';
    if (value == 'hi' || value == 'ta' || value == 'te' || value == 'en') return value;
    return 'en';
  }
}
