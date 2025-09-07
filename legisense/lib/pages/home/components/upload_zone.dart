import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import '../../../theme/app_theme.dart';

class UploadZone extends StatefulWidget {
  const UploadZone({super.key});

  @override
  State<UploadZone> createState() => _UploadZoneState();
}

class _UploadZoneState extends State<UploadZone> {
  final bool _isDragOver = false;
  bool _isLoading = false;
  Future<void> _pickDocument() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'doc', 'docx', 'ppt', 'pptx'],
        withData: false,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final PlatformFile file = result.files.single;
        _processDocumentFromPath(file.path ?? file.name);
      }
    } catch (e) {
      _showErrorDialog('Failed to pick document: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _processDocumentFromPath(String pathOrName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Document selected: $pathOrName'),
        backgroundColor: AppTheme.successGreen,
        duration: const Duration(seconds: 3),
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
  

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingS + 6, vertical: AppTheme.spacingS + 6),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
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
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryBlueLight, AppTheme.primaryBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(27),
              ),
              child: const Icon(
                FontAwesomeIcons.cloudArrowUp,
                color: Colors.white,
                size: 20,
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.8, 0.8),
                  duration: AppTheme.animationMedium,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: AppTheme.animationSlow, delay: 200.ms),
            
            const SizedBox(height: AppTheme.spacingS + 6),
            
            // Title and Description
            Text(
              'Upload a Document',
              style: AppTheme.heading4,
            )
                .animate()
                .slideY(
                  begin: 0.3,
                  duration: AppTheme.animationMedium,
                  curve: Curves.easeOut,
                )
                .fadeIn(duration: AppTheme.animationSlow, delay: 400.ms),
            
            const SizedBox(height: AppTheme.spacingXS + 2),
            
            Text(
              'Select a PDF, DOC/DOCX, or PPT/PPTX to process',
              style: AppTheme.bodySmall,
            )
                .animate()
                .slideY(
                  begin: 0.3,
                  duration: AppTheme.animationMedium,
                  curve: Curves.easeOut,
                )
                .fadeIn(duration: AppTheme.animationSlow, delay: 600.ms),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Action Buttons
            Column(
              children: [
                // Upload Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _pickDocument,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlueLight,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS + 6),
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
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingS),
                              Text(
                                'Opening picker...',
                                style: AppTheme.buttonPrimary,
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                FontAwesomeIcons.fileArrowUp,
                                size: 14,
                              ),
                              const SizedBox(width: AppTheme.spacingS),
                              Text(
                                'Upload Document',
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
                
                const SizedBox(height: AppTheme.spacingS + 6),
                
                // Secondary: Browse Files (same action)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _pickDocument,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      side: BorderSide(
                        color: AppTheme.backgroundWhite.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS + 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          FontAwesomeIcons.folderOpen,
                          size: 14,
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        Text(
                          'Browse Files',
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
