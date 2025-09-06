import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../components/main_header.dart';
import '../../theme/app_theme.dart';
import 'components/profile_avatar.dart';
import 'components/user_info_section.dart';
import 'components/info_card.dart';
import 'components/action_buttons.dart';

class ProfilePage extends StatelessWidget {
  final VoidCallback? onLogout;
  
  const ProfilePage({
    super.key,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MainHeader(title: 'Profile'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppTheme.spacingL),
                    // Profile Avatar
                    Center(
                      child: ProfileAvatar(
                        initials: 'DU',
                        size: 120,
                        showRing: true,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXL),
                    // User Info Section
                    UserInfoSection(
                      name: 'Demo User',
                      email: 'demo@legisense.com',
                      role: 'Small Business Owner',
                      onEdit: () {
                        // TODO: Implement edit profile
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingXL),
                    // Personal Information Card
                    InfoCard(
                      title: 'Personal Information',
                      delay: 600,
                      onEdit: () {
                        // TODO: Implement edit personal info
                      },
                      fields: [
                        InfoField(
                          icon: FontAwesomeIcons.user,
                          label: 'Full Name',
                          value: 'Demo User',
                          hint: 'Enter your full name',
                          isEditable: true,
                        ),
                        InfoField(
                          icon: FontAwesomeIcons.envelope,
                          label: 'Email Address',
                          value: 'demo@legisense.com',
                          hint: 'Enter your email',
                          isEditable: true,
                        ),
                        InfoField(
                          icon: FontAwesomeIcons.phone,
                          label: 'Phone Number',
                          value: '+1 (555) 123-4567',
                          hint: 'Enter your phone number',
                          isEditable: true,
                        ),
                        InfoField(
                          icon: FontAwesomeIcons.building,
                          label: 'Company',
                          value: 'Legisense Inc.',
                          hint: 'Enter your company name',
                          isEditable: true,
                        ),
                      ],
                    ),
                    // Preferences Card
                    InfoCard(
                      title: 'Preferences',
                      delay: 800,
                      onEdit: () {
                        // TODO: Implement edit preferences
                      },
                      fields: [
                        InfoField(
                          icon: FontAwesomeIcons.globe,
                          label: 'Language',
                          value: 'English (US)',
                          hint: 'Select your language',
                          isEditable: true,
                        ),
                        InfoField(
                          icon: FontAwesomeIcons.clock,
                          label: 'Time Zone',
                          value: 'Pacific Standard Time',
                          hint: 'Select your time zone',
                          isEditable: true,
                        ),
                        InfoField(
                          icon: FontAwesomeIcons.bell,
                          label: 'Notifications',
                          value: 'Email & Push',
                          hint: 'Select notification preferences',
                          isEditable: true,
                        ),
                      ],
                    ),
                    // Privacy Settings Card
                    InfoCard(
                      title: 'Privacy Settings',
                      delay: 1000,
                      onEdit: () {
                        // TODO: Implement edit privacy settings
                      },
                      fields: [
                        InfoField(
                          icon: FontAwesomeIcons.lock,
                          label: 'Data Sharing',
                          value: 'Limited',
                          hint: 'Control data sharing preferences',
                          isEditable: true,
                        ),
                        InfoField(
                          icon: FontAwesomeIcons.shield,
                          label: 'Security Level',
                          value: 'High',
                          hint: 'Set your security level',
                          isEditable: true,
                        ),
                        InfoField(
                          icon: FontAwesomeIcons.eye,
                          label: 'Profile Visibility',
                          value: 'Private',
                          hint: 'Control who can see your profile',
                          isEditable: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingXL),
                    // Action Buttons
                    ActionButtons(
                      delay: 1200,
                      onEditProfile: () {
                        // TODO: Implement edit profile
                      },
                      onManagePrivacy: () {
                        // TODO: Implement manage privacy
                      },
                      onLogout: onLogout,
                    ),
                    const SizedBox(height: AppTheme.spacingL),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
