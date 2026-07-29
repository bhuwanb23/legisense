import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/pending_upload.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/auth_primary_button.dart';

/// Camera capture preview — mock edge frame + OCR, then return [PendingUpload].
class ScanPreviewPage extends StatefulWidget {
  const ScanPreviewPage({super.key, required this.imagePath});

  final String imagePath;

  @override
  State<ScanPreviewPage> createState() => _ScanPreviewPageState();
}

class _ScanPreviewPageState extends State<ScanPreviewPage> {
  late String _path = widget.imagePath;
  bool _ocrRunning = false;

  Future<void> _retake() async {
    final picker = ImagePicker();
    final shot = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (shot == null || !mounted) return;
    setState(() => _path = shot.path);
  }

  Future<void> _usePhoto() async {
    if (_ocrRunning) return;
    setState(() => _ocrRunning = true);
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    Navigator.of(context).pop(
      PendingUpload(
        source: UploadSource.scan,
        title: 'Scanned document',
        detail: 'OCR text extracted (demo)',
        localPath: _path,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.cloud,
        title: Text(
          'Scan document',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      child: Image.file(
                        File(_path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    // Mock auto-crop guide
                    IgnorePointer(
                      child: Container(
                        margin: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.accentSky,
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                    if (_ocrRunning)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cloud.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              'Running OCR…',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Edges detected — adjust framing if needed',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.cloud.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _ocrRunning ? null : _retake,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.cloud,
                        side: const BorderSide(color: AppColors.cloud),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                      ),
                      child: Text(
                        'Retake',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: AuthPrimaryButton(
                      label: 'Use Photo',
                      loading: _ocrRunning,
                      onPressed: _usePhoto,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
