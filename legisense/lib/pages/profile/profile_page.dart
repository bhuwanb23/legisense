import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../components/main_header.dart';

class ProfilePage extends StatelessWidget {
  final VoidCallback? onLogout;
  
  const ProfilePage({
    super.key,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MainHeader(title: 'Profile'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Manage your account and preferences',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6B7280),
                      ),
                    )
                        .animate()
                        .slideX(
                          begin: -0.3,
                          duration: 600.ms,
                          curve: Curves.easeOut,
                        )
                        .fadeIn(duration: 800.ms, delay: 200.ms),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: const Icon(
                              FontAwesomeIcons.user,
                              color: Colors.white,
                              size: 32,
                            ),
                          )
                              .animate()
                              .scale(
                                begin: const Offset(0.8, 0.8),
                                duration: 600.ms,
                                curve: Curves.elasticOut,
                              )
                              .fadeIn(duration: 800.ms, delay: 400.ms),
                          const SizedBox(height: 16),
                          Text(
                            'Demo User',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1F2937),
                            ),
                          )
                              .animate()
                              .slideY(
                                begin: 0.3,
                                duration: 600.ms,
                                curve: Curves.easeOut,
                              )
                              .fadeIn(duration: 800.ms, delay: 600.ms),
                          const SizedBox(height: 4),
                          Text(
                            'demo@legisense.com',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF6B7280),
                            ),
                          )
                              .animate()
                              .slideY(
                                begin: 0.3,
                                duration: 600.ms,
                                curve: Curves.easeOut,
                              )
                              .fadeIn(duration: 800.ms, delay: 800.ms),
                        ],
                      ),
                    )
                        .animate()
                        .slideY(
                          begin: 0.3,
                          duration: 600.ms,
                          curve: Curves.easeOut,
                        )
                        .fadeIn(duration: 800.ms, delay: 400.ms),
                    const SizedBox(height: 32),
                    Text(
                      'Settings',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    )
                        .animate()
                        .slideY(
                          begin: 0.3,
                          duration: 600.ms,
                          curve: Curves.easeOut,
                        )
                        .fadeIn(duration: 800.ms, delay: 1000.ms),
                    const SizedBox(height: 16),
                    _buildSettingItem(
                      icon: FontAwesomeIcons.bell,
                      title: 'Notifications',
                      subtitle: 'Manage your notification preferences',
                      delay: 1200,
                    ),
                    _buildSettingItem(
                      icon: FontAwesomeIcons.shield,
                      title: 'Privacy & Security',
                      subtitle: 'Control your privacy settings',
                      delay: 1400,
                    ),
                    _buildSettingItem(
                      icon: FontAwesomeIcons.gear,
                      title: 'Preferences',
                      subtitle: 'Customize your experience',
                      delay: 1600,
                    ),
                    _buildSettingItem(
                      icon: FontAwesomeIcons.circleQuestion,
                      title: 'Help & Support',
                      subtitle: 'Get help and contact support',
                      delay: 1800,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFECACA),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            onLogout?.call();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                FontAwesomeIcons.rightFromBracket,
                                color: Color(0xFFDC2626),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Logout',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0.9, 0.9),
                          duration: 600.ms,
                          curve: Curves.elasticOut,
                        )
                        .fadeIn(duration: 800.ms, delay: 2000.ms),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required int delay,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF2563EB),
              size: 16,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                
                const SizedBox(height: 2),
                
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          
          const Icon(
            FontAwesomeIcons.chevronRight,
            size: 12,
            color: Color(0xFF9CA3AF),
          ),
        ],
      ),
    )
        .animate()
        .slideX(
          begin: 0.3,
          duration: 600.ms,
          curve: Curves.easeOut,
        )
        .fadeIn(duration: 800.ms, delay: delay.ms);
  }
}
