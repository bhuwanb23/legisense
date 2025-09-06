import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../../theme/app_theme.dart';

class UploadZone extends StatefulWidget {
  const UploadZone({super.key});

  @override
  State<UploadZone> createState() => _UploadZoneState();
}

class _UploadZoneState extends State<UploadZone> {
  final bool _isDragOver = false;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Camera Permission Required'),
          content: const Text(
            'This app needs camera permission to capture document images. Please enable it in settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Settings'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _captureImage() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Request camera permission
      await _requestCameraPermission();
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        _processImage(image);
      }
    } catch (e) {
      _showErrorDialog('Failed to capture image: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        _processImage(image);
      }
    } catch (e) {
      _showErrorDialog('Failed to pick image: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _processImage(XFile image) {
    // Here you would typically process the image
    // For now, we'll just show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Image captured: ${image.name}'),
        backgroundColor: AppTheme.successGreen,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to image preview or document processing
            _showImagePreview(image);
          },
        ),
      ),
    );
  }

  void _showImagePreview(XFile image) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Captured Image',
                  style: AppTheme.heading4,
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(image.path),
                    width: 300,
                    height: 400,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Process the document here
                        _processDocument(image);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Process Document'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _processDocument(XFile image) {
    // This is where you would implement document processing logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Document processing started...'),
        backgroundColor: AppTheme.primaryBlue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Image Source',
                style: AppTheme.heading4,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(FontAwesomeIcons.camera, color: AppTheme.primaryBlue),
                title: const Text('Take Photo'),
                subtitle: const Text('Capture document with camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _captureImage();
                },
              ),
              ListTile(
                leading: const Icon(FontAwesomeIcons.image, color: AppTheme.primaryBlue),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select document from gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM, vertical: AppTheme.spacingM),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          color: AppTheme.backgroundWhite.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(
            color: _isDragOver 
                ? AppTheme.primaryBlueLight 
                : AppTheme.secondaryBlueLight,
            width: 2,
            style: BorderStyle.solid,
          ),
          boxShadow: _isDragOver
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlueLight.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          children: [
            // Upload Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryBlueLight, AppTheme.primaryBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                FontAwesomeIcons.cloudArrowUp,
                color: Colors.white,
                size: 24,
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.8, 0.8),
                  duration: AppTheme.animationMedium,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: AppTheme.animationSlow, delay: 200.ms),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Title and Description
            Text(
              'Capture Your Document',
              style: AppTheme.heading4,
            )
                .animate()
                .slideY(
                  begin: 0.3,
                  duration: AppTheme.animationMedium,
                  curve: Curves.easeOut,
                )
                .fadeIn(duration: AppTheme.animationSlow, delay: 400.ms),
            
            const SizedBox(height: AppTheme.spacingS),
            
            Text(
              'Take a photo or select from gallery to process your document',
              style: AppTheme.bodySmall,
            )
                .animate()
                .slideY(
                  begin: 0.3,
                  duration: AppTheme.animationMedium,
                  curve: Curves.easeOut,
                )
                .fadeIn(duration: AppTheme.animationSlow, delay: 600.ms),
            
            const SizedBox(height: AppTheme.spacingL),
            
            // Action Buttons
            Column(
              children: [
                // Upload Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _showImageSourceDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlueLight,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      elevation: 8,
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingS),
                              Text(
                                'Processing...',
                                style: AppTheme.buttonPrimary,
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                FontAwesomeIcons.camera,
                                size: 16,
                              ),
                              const SizedBox(width: AppTheme.spacingS),
                              Text(
                                'Capture Document',
                                style: AppTheme.buttonPrimary,
                              ),
                            ],
                          ),
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      duration: AppTheme.animationMedium,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: AppTheme.animationSlow, delay: 800.ms),
                
                const SizedBox(height: AppTheme.spacingM),
                
                // Sample Document Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _pickImageFromGallery,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      side: BorderSide(
                        color: AppTheme.backgroundWhite.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          FontAwesomeIcons.image,
                          size: 16,
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        Text(
                          'Choose from Gallery',
                          style: AppTheme.buttonSecondary,
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      duration: AppTheme.animationMedium,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: AppTheme.animationSlow, delay: 1000.ms),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
