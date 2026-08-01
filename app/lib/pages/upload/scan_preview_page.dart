import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/pending_upload.dart';
import '../../theme/app_insets.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/auth_primary_button.dart';

/// Camera capture preview — then return [PendingUpload] for upload/OCR on process.
class ScanPreviewPage extends StatefulWidget {
  const ScanPreviewPage({super.key, required this.imagePath});

  final String imagePath;

  @override
  State<ScanPreviewPage> createState() => _ScanPreviewPageState();
}

class _ScanPreviewPageState extends State<ScanPreviewPage> {
  late String _path = widget.imagePath;
  Uint8List? _bytes;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadBytes();
  }

  Future<void> _loadBytes() async {
    try {
      final b = await XFile(_path).readAsBytes();
      if (mounted) setState(() => _bytes = b);
    } catch (_) {}
  }

  Future<void> _retake() async {
    final picker = ImagePicker();
    final shot = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (shot == null || !mounted) return;
    setState(() {
      _path = shot.path;
      _bytes = null;
    });
    await _loadBytes();
  }

  Future<void> _replaceFromGallery() async {
    final picker = ImagePicker();
    final shot = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
      maxWidth: 2000,
    );
    if (shot == null || !mounted) return;
    setState(() {
      _path = shot.path;
      _bytes = null;
    });
    await _loadBytes();
  }

  Future<void> _usePhoto() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = _bytes ?? await XFile(_path).readAsBytes();
      if (!mounted) return;
      Navigator.of(context).pop(
        PendingUpload(
          source: UploadSource.scan,
          title: 'Scanned document',
          detail: 'Image ready — OCR runs during analysis',
          localPath: _path,
          bytes: bytes,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read image')),
      );
    }
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
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            AppInsets.footerAboveDock(context),
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      child: _bytes != null
                          ? Image.memory(
                              _bytes!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            )
                          : (!kIsWeb
                              ? Image.file(
                                  File(_path),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                )
                              : const Center(
                                  child: CircularProgressIndicator(),
                                )),
                    ),
                    if (_busy)
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
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Preparing…',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
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
                'Adjust framing, then continue. Text extraction runs during analysis.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.cloud.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : _retake,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.cloud,
                        side: BorderSide(
                          color: AppColors.cloud.withValues(alpha: 0.5),
                        ),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Retake'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : _replaceFromGallery,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.cloud,
                        side: BorderSide(
                          color: AppColors.cloud.withValues(alpha: 0.5),
                        ),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Replace'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AuthPrimaryButton(
                label: 'Use Photo',
                loading: _busy,
                onPressed: _usePhoto,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
