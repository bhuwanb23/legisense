import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../components/main_header.dart';
import '../../theme/app_theme.dart';
import 'components/components.dart';

class ProfilePage extends StatelessWidget {
  final VoidCallback? onLogout;
  
  const ProfilePage({
    super.key,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8FAFC), // slate-50
              Color(0xFFEFF6FF), // blue-50
              Color(0xFFF0F9FF), // sky-50
              Color(0xFFF5F3FF), // purple-50
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Animated background elements
              _buildAnimatedBackground(),
              
              // Main content
              SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Global Main Header with enhanced animation
                    const MainHeader(title: 'Profile')
                        .animate()
                        .slideY(
                          begin: -0.5,
                          duration: AppTheme.animationSlow,
                          curve: Curves.elasticOut,
                        )
                        .fadeIn(duration: AppTheme.animationSlow),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppTheme.spacingM),
                          
                          // Avatar Section with enhanced animation
                          Center(
                            child: AvatarSection(
                              initials: 'SJ',
                              name: 'Sarah Johnson',
                              email: 'sarah.johnson@company.com',
                              role: 'Senior Product Manager',
                              onCameraTap: () {
                                // TODO: Implement camera tap
                              },
                            )
                                .animate()
                                .scale(
                                  begin: const Offset(0.5, 0.5),
                                  duration: AppTheme.animationSlow,
                                  curve: Curves.elasticOut,
                                )
                                .fadeIn(duration: AppTheme.animationSlow, delay: 200.ms),
                          ),
                          
                          const SizedBox(height: AppTheme.spacingL),
                          
                          // Personal Info Card with slide animation
                          PersonalInfoCard(
                            fullName: 'Sarah Johnson',
                            phoneNumber: '+1 (555) 123-4567',
                            location: 'San Francisco, CA',
                            onNameChanged: (value) {
                              // TODO: Implement name change
                            },
                            onPhoneChanged: (value) {
                              // TODO: Implement phone change
                            },
                            onLocationChanged: (value) {
                              // TODO: Implement location change
                            },
                          )
                              .animate()
                              .slideY(
                                begin: 0.3,
                                duration: AppTheme.animationSlow,
                                curve: Curves.easeOut,
                              )
                              .fadeIn(duration: AppTheme.animationSlow, delay: 400.ms),
                          
                          const SizedBox(height: AppTheme.spacingM),
                          
                          // Preferences Card with slide animation
                          PreferencesCard(
                            emailNotifications: true,
                            pushNotifications: false,
                            language: 'English (US)',
                            onEmailNotificationsChanged: (value) {
                              // TODO: Implement email notifications change
                            },
                            onPushNotificationsChanged: (value) {
                              // TODO: Implement push notifications change
                            },
                            onLanguageChanged: (value) {
                              // TODO: Implement language change
                            },
                          )
                              .animate()
                              .slideX(
                                begin: -0.3,
                                duration: AppTheme.animationSlow,
                                curve: Curves.easeOut,
                              )
                              .fadeIn(duration: AppTheme.animationSlow, delay: 600.ms),
                          
                          const SizedBox(height: AppTheme.spacingM),
                          
                          // Privacy Settings Card with slide animation
                          PrivacySettingsCard(
                            profileVisibility: 'Public',
                            dataSharing: 'Limited',
                            twoFactorAuth: true,
                            onProfileVisibilityTap: () {
                              // TODO: Implement profile visibility tap
                            },
                            onDataSharingTap: () {
                              // TODO: Implement data sharing tap
                            },
                            onTwoFactorAuthTap: () {
                              // TODO: Implement two factor auth tap
                            },
                          )
                              .animate()
                              .slideX(
                                begin: 0.3,
                                duration: AppTheme.animationSlow,
                                curve: Curves.easeOut,
                              )
                              .fadeIn(duration: AppTheme.animationSlow, delay: 800.ms),
                          
                          const SizedBox(height: AppTheme.spacingM),
                          
                          // Saved Simulations Card with slide animation
                          SavedSimulationsCard(
                            onCreateSimulation: () {
                              // TODO: Implement create simulation
                            },
                          )
                              .animate()
                              .slideY(
                                begin: 0.3,
                                duration: AppTheme.animationSlow,
                                curve: Curves.easeOut,
                              )
                              .fadeIn(duration: AppTheme.animationSlow, delay: 1000.ms),
                          
                          const SizedBox(height: AppTheme.spacingL),
                          
                          // Action Buttons with enhanced animation
                          ProfileActionButtons(
                            onEditProfile: () {
                              // TODO: Implement edit profile
                            },
                            onManagePrivacy: () {
                              // TODO: Implement manage privacy
                            },
                            onLogout: onLogout,
                          )
                              .animate()
                              .slideY(
                                begin: 0.3,
                                duration: AppTheme.animationSlow,
                                curve: Curves.easeOut,
                              )
                              .fadeIn(duration: AppTheme.animationSlow, delay: 1200.ms),
                          
                          const SizedBox(height: AppTheme.spacingL),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        // Floating geometric shapes
        Positioned(
          top: 100,
          right: 40,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(40),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.2, 1.2),
                duration: 4000.ms,
                curve: Curves.easeInOut,
              )
              .then()
              .scale(
                begin: const Offset(1.2, 1.2),
                end: const Offset(0.8, 0.8),
                duration: 4000.ms,
                curve: Curves.easeInOut,
              ),
        ),
        Positioned(
          top: 250,
          left: 30,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(
                begin: 0,
                end: 2 * 3.14159,
                duration: 15000.ms,
                curve: Curves.linear,
              ),
        ),
        Positioned(
          bottom: 300,
          right: 60,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.warningOrange.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.5, 1.5),
                duration: 3000.ms,
                curve: Curves.easeInOut,
              )
              .then()
              .scale(
                begin: const Offset(1.5, 1.5),
                end: const Offset(1.0, 1.0),
                duration: 3000.ms,
                curve: Curves.easeInOut,
              ),
        ),
        // Floating particles
        ...List.generate(3, (index) {
          return Positioned(
            top: 200 + (index * 150),
            left: 80 + (index * 80),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .fadeIn(
                  duration: 1500.ms,
                  delay: (index * 800).ms,
                )
                .then()
                .fadeOut(duration: 1500.ms)
                .then()
                .fadeIn(duration: 1500.ms),
          );
        }),
      ],
    );
  }
}
