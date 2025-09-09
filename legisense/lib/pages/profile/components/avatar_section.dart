import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:io';
import '../../../theme/app_theme.dart';

class AvatarSection extends StatefulWidget {
  final String? imageUrl;
  final File? selectedImage;
  final String initials;
  final String name;
  final String email;
  final String role;
  final VoidCallback? onCameraTap;

  const AvatarSection({
    super.key,
    this.imageUrl,
    this.selectedImage,
    required this.initials,
    required this.name,
    required this.email,
    required this.role,
    this.onCameraTap,
  });

  @override
  State<AvatarSection> createState() => _AvatarSectionState();
}

class _AvatarSectionState extends State<AvatarSection> {
  bool _cameraPressed = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar with camera button
        Stack(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                  width: 4,
                ),
              ),
              child: widget.selectedImage != null
                  ? ClipOval(
                      child: Image.file(
                        widget.selectedImage!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildInitialsAvatar();
                        },
                      ),
                    )
                  : widget.imageUrl != null
                      ? ClipOval(
                          child: Image.network(
                            widget.imageUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildInitialsAvatar();
                            },
                          ),
                        )
                      : _buildInitialsAvatar(),
            ),
            // Camera button
            Positioned(
              bottom: -4,
              right: -4,
              child: Listener(
                onPointerDown: (_) => setState(() => _cameraPressed = true),
                onPointerUp: (_) => setState(() => _cameraPressed = false),
                onPointerCancel: (_) => setState(() => _cameraPressed = false),
                child: GestureDetector(
                  onTap: widget.onCameraTap,
                  child: AnimatedScale(
                    scale: _cameraPressed ? 0.92 : 1.0,
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOut,
                    child: Material(
                      color: Colors.transparent,
                      child: Ink(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          FontAwesomeIcons.camera,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppTheme.spacingM),
        
        // Name
        Text(
          widget.name,
          style: AppTheme.heading3.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: AppTheme.spacingXS),
        
        // Email
        Text(
          widget.email,
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: AppTheme.spacingXS),
        
        // Role
        Text(
          widget.role,
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInitialsAvatar() {
    return Center(
      child: Text(
        widget.initials,
        style: AppTheme.heading2.copyWith(
          color: AppTheme.primaryBlue,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
