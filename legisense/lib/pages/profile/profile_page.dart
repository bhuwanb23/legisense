import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../components/main_header.dart';
import '../../theme/app_theme.dart';
import 'components/components.dart';
// imports provided transitively by components/components.dart
import '../../main.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback? onLogout;
  
  const ProfilePage({
    super.key,
    this.onLogout,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Profile data
  String _fullName = 'Sarah Johnson';
  String _phoneNumber = '+1 (555) 123-4567';
  String _location = 'San Francisco, CA';
  final String _email = 'sarah.johnson@company.com';
  final String _role = 'Senior Product Manager';
  String _initials = 'SJ';
  
  // Settings
  bool _emailNotifications = true;
  bool _pushNotifications = false;
  String _language = 'en';
  String _profileVisibility = 'Public';
  String _dataSharing = 'Limited';
  bool _twoFactorAuth = true;
  
  // Avatar
  File? _selectedImage;

  // Lightweight loading state for timeline
  bool _loadingTimeline = true;

  final LanguageController _languageController = appLanguageController;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _loadingTimeline = false);
    });
  }

  @override
  void dispose() {
    _languageController.dispose();
    super.dispose();
  }

  // Camera tap functionality
  Future<void> _onCameraTap() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully!'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile picture: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  // Name change functionality
  void _onNameChanged(String value) {
    setState(() {
      _fullName = value;
      _initials = _generateInitials(value);
    });
  }

  // Phone change functionality
  void _onPhoneChanged(String value) {
    setState(() {
      _phoneNumber = value;
    });
  }

  // Location change functionality
  void _onLocationChanged(String value) {
    setState(() {
      _location = value;
    });
  }

  // Email notifications change
  void _onEmailNotificationsChanged(bool value) {
    setState(() {
      _emailNotifications = value;
    });
  }

  // Push notifications change
  void _onPushNotificationsChanged(bool value) {
    setState(() {
      _pushNotifications = value;
    });
  }

  // Language change functionality
  void _onLanguageChanged(String value) {
    setState(() {
      _language = value;
    });
  }

  // Profile visibility tap
  void _onProfileVisibilityTap() {
    _showSelectionDialog(
      'Profile Visibility',
      ['Public', 'Friends Only', 'Private'],
      _profileVisibility,
      (value) => setState(() => _profileVisibility = value),
    );
  }

  // Data sharing tap
  void _onDataSharingTap() {
    _showSelectionDialog(
      'Data Sharing',
      ['None', 'Limited', 'Full'],
      _dataSharing,
      (value) => setState(() => _dataSharing = value),
    );
  }

  // Two factor auth tap
  void _onTwoFactorAuthTap() {
    setState(() {
      _twoFactorAuth = !_twoFactorAuth;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_twoFactorAuth 
          ? 'Two-factor authentication enabled' 
          : 'Two-factor authentication disabled'),
        backgroundColor: _twoFactorAuth ? AppTheme.successGreen : AppTheme.warningOrange,
      ),
    );
  }

  // Create simulation functionality
  void _onCreateSimulation() {
    // Navigate to simulation page
    Navigator.of(context).pushNamed('/simulation');
  }

  // Edit profile functionality
  void _onEditProfile() {
    _showEditProfileDialog();
  }

  // Manage privacy functionality
  void _onManagePrivacy() {
    _showPrivacySettingsDialog();
  }

  // Helper methods
  String _generateInitials(String name) {
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty) {
      return words[0][0].toUpperCase();
    }
    return 'U';
  }

  void _showSelectionDialog(String title, List<String> options, String current, Function(String) onChanged) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) => ListTile(
            title: Text(option),
            leading: Icon(
              option == current ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: option == current ? AppTheme.primaryBlue : Colors.grey,
            ),
            onTap: () {
              onChanged(option);
              Navigator.of(context).pop();
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _fullName);
    final phoneController = TextEditingController(text: _phoneNumber);
    final locationController = TextEditingController(text: _location);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _onNameChanged(nameController.text);
              _onPhoneChanged(phoneController.text);
              _onLocationChanged(locationController.text);
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile updated successfully!'),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPrivacySettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Email Notifications'),
              value: _emailNotifications,
              onChanged: _onEmailNotificationsChanged,
            ),
            SwitchListTile(
              title: const Text('Push Notifications'),
              value: _pushNotifications,
              onChanged: _onPushNotificationsChanged,
            ),
            SwitchListTile(
              title: const Text('Two-Factor Authentication'),
              value: _twoFactorAuth,
              onChanged: (value) => setState(() => _twoFactorAuth = value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingTimeline) {}
    return LanguageScope(
      controller: _languageController,
      child: Builder(
        builder: (context) {
          final controller = LanguageScope.of(context);
          final i18n = ProfileI18n.mapFor(controller.language);
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
              
              // Main content below fixed header
              SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 128),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppTheme.spacingM),
                          
                          // Avatar Section with enhanced animation
                          Center(
                            child: AvatarSection(
                              initials: _initials,
                              name: _fullName,
                              email: _email,
                              role: _role,
                              onCameraTap: _onCameraTap,
                              selectedImage: _selectedImage,
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
                            fullName: _fullName,
                            phoneNumber: _phoneNumber,
                            location: _location,
                            onNameChanged: _onNameChanged,
                            onPhoneChanged: _onPhoneChanged,
                            onLocationChanged: _onLocationChanged,
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
                            emailNotifications: _emailNotifications,
                            pushNotifications: _pushNotifications,
                            language: _language,
                            onEmailNotificationsChanged: _onEmailNotificationsChanged,
                            onPushNotificationsChanged: _onPushNotificationsChanged,
                            onLanguageChanged: _onLanguageChanged,
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
                            profileVisibility: _profileVisibility,
                            dataSharing: _dataSharing,
                            twoFactorAuth: _twoFactorAuth,
                            onProfileVisibilityTap: _onProfileVisibilityTap,
                            onDataSharingTap: _onDataSharingTap,
                            onTwoFactorAuthTap: _onTwoFactorAuthTap,
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
                            onCreateSimulation: _onCreateSimulation,
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
                            onEditProfile: _onEditProfile,
                            onManagePrivacy: _onManagePrivacy,
                            onLogout: widget.onLogout,
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

              // Fixed header pinned at the very top-most layer (over content)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    color: Colors.white,
                    child: MainHeader(title: i18n['profile.title'] ?? 'Profile'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
        },
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
