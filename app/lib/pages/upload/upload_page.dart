import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/pending_upload.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/upload/upload_option_tile.dart';
import '../processing/processing_page.dart';
import 'scan_preview_page.dart';

/// Page 11 — Universal upload + OCR scan entry.
class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  static const _maxBytes = 20 * 1024 * 1024; // 20 MB

  PendingUpload? _pending;

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx', 'txt'],
      withData: false,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    final file = result.files.single;
    if (file.size > _maxBytes) {
      _toast('File must be under 20 MB');
      return;
    }
    setState(() {
      _pending = PendingUpload(
        source: UploadSource.file,
        title: file.name,
        detail: _formatSize(file.size),
        localPath: file.path,
      );
    });
  }

  Future<void> _scanDocument() async {
    final picker = ImagePicker();
    final shot = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (shot == null || !mounted) return;

    final upload = await Navigator.of(context).push<PendingUpload>(
      MaterialPageRoute<PendingUpload>(
        builder: (_) => ScanPreviewPage(imagePath: shot.path),
      ),
    );
    if (upload == null || !mounted) return;
    setState(() => _pending = upload);
  }

  Future<void> _pasteText() async {
    final controller = TextEditingController();
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cloud,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Paste text',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 8,
                autofocus: true,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.primaryNavy,
                ),
                decoration: InputDecoration(
                  hintText: 'Paste contract text here…',
                  hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.inkSoft),
                  filled: true,
                  fillColor: const Color(0xFFF3F7FC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AuthPrimaryButton(
                label: 'Use text',
                onPressed: () {
                  Navigator.pop(context, controller.text.trim());
                },
              ),
            ],
          ),
        );
      },
    );
    if (text == null || text.isEmpty || !mounted) return;
    setState(() {
      _pending = PendingUpload(
        source: UploadSource.paste,
        title: 'Pasted document',
        detail: '${text.length} characters',
      );
    });
  }

  Future<void> _importUrl() async {
    final controller = TextEditingController();
    final url = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cloud,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Import URL',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.url,
                autofocus: true,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.primaryNavy,
                ),
                decoration: InputDecoration(
                  hintText: 'https://…',
                  hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.inkSoft),
                  filled: true,
                  fillColor: const Color(0xFFF3F7FC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AuthPrimaryButton(
                label: 'Import',
                onPressed: () {
                  Navigator.pop(context, controller.text.trim());
                },
              ),
            ],
          ),
        );
      },
    );
    if (url == null || url.isEmpty || !mounted) return;
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      _toast('Enter a valid http(s) URL');
      return;
    }
    setState(() {
      _pending = PendingUpload(
        source: UploadSource.url,
        title: uri.host.isEmpty ? url : uri.host,
        detail: url,
      );
    });
  }

  void _proceed() {
    final upload = _pending;
    if (upload == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProcessingPage(upload: upload),
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.primaryNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final pending = _pending;

    return ColoredBox(
      color: AppColors.paper,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 110),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    'Upload document',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose how you want to add a contract for review.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      height: 1.45,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: UploadOptionTile(
                          icon: Icons.folder_open_rounded,
                          title: 'Upload File',
                          subtitle: 'PDF / DOCX / TXT',
                          selected: pending?.source == UploadSource.file,
                          onTap: _pickFile,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: UploadOptionTile(
                          icon: Icons.document_scanner_outlined,
                          title: 'Scan',
                          subtitle: 'Camera OCR',
                          selected: pending?.source == UploadSource.scan,
                          onTap: _scanDocument,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: UploadOptionTile(
                          icon: Icons.content_paste_rounded,
                          title: 'Paste Text',
                          subtitle: 'Clipboard',
                          selected: pending?.source == UploadSource.paste,
                          onTap: _pasteText,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: UploadOptionTile(
                          icon: Icons.link_rounded,
                          title: 'Import URL',
                          subtitle: 'Public link',
                          selected: pending?.source == UploadSource.url,
                          onTap: _importUrl,
                        ),
                      ),
                    ],
                  ),
                  if (pending != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cloud,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(color: AppColors.accentSoft),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.insert_drive_file_outlined,
                            color: AppColors.primaryNavy,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pending.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryNavy,
                                  ),
                                ),
                                if (pending.detail != null)
                                  Text(
                                    pending.detail!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: AppColors.inkSoft,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _pending = null),
                            icon: const Icon(Icons.close_rounded),
                            color: AppColors.inkSoft,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  _InfoLine(
                    icon: Icons.sd_storage_outlined,
                    text: 'Max file size: 20 MB',
                  ),
                  const SizedBox(height: 10),
                  _InfoLine(
                    icon: Icons.description_outlined,
                    text: 'Supported: PDF, DOC, DOCX, TXT',
                  ),
                  const SizedBox(height: 10),
                  _InfoLine(
                    icon: Icons.lock_outline_rounded,
                    text:
                        'Your document is encrypted and auto-deleted after processing',
                  ),
                  const SizedBox(height: 28),
                  AuthPrimaryButton(
                    label: 'Proceed',
                    onPressed: pending == null ? null : _proceed,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.inkSoft),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              height: 1.4,
              color: AppColors.inkSoft,
            ),
          ),
        ),
      ],
    );
  }
}
