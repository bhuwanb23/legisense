import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/pending_upload.dart';
import '../../repositories/documents_repository.dart';
import '../../services/api_exception.dart';
import '../../services/session_prefs.dart';
import '../../theme/app_insets.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/home/app_page_header.dart';
import '../processing/processing_page.dart';
import 'scan_preview_page.dart';

/// Upload — TripGlide drop-zone hero + secondary methods.
class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage>
    with SingleTickerProviderStateMixin {
  static const _maxBytes = 10 * 1024 * 1024; // 10 MB (backend limit)

  PendingUpload? _pending;
  bool _uploading = false;
  bool _heroPressed = false;

  AnimationController? _enter;

  @override
  void initState() {
    super.initState();
    _ensureEnter();
  }

  @override
  void dispose() {
    _enter?.dispose();
    super.dispose();
  }

  /// Survives hot reload when `late` fields were added without re-running initState.
  AnimationController _ensureEnter() {
    final existing = _enter;
    if (existing != null) return existing;
    final created = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    )..forward();
    _enter = created;
    return created;
  }

  Animation<double> _fade(double begin, double end) {
    return CurvedAnimation(
      parent: _ensureEnter(),
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
  }

  Animation<Offset> _slide(double begin, double end) {
    return Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _ensureEnter(),
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    final file = result.files.single;
    if (file.size > _maxBytes) {
      _toast('File must be under 10 MB');
      return;
    }
    final bytes = file.bytes;
    if (bytes == null) {
      _toast('Could not read file bytes');
      return;
    }
    setState(() {
      _pending = PendingUpload(
        source: UploadSource.file,
        title: file.name,
        detail: _formatSize(file.size),
        localPath: file.path,
        bytes: bytes,
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
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.chip,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Paste text',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Drop contract text below to review.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.mute,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 8,
                autofocus: true,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.ink,
                ),
                decoration: InputDecoration(
                  hintText: 'Paste contract text here…',
                  hintStyle:
                      GoogleFonts.plusJakartaSans(color: AppColors.mute),
                  filled: true,
                  fillColor: AppColors.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.field),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AuthPrimaryButton(
                label: 'Use text',
                showArrow: true,
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
        text: text,
      );
    });
  }

  Future<void> _importUrl() async {
    final controller = TextEditingController();
    final url = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.chip,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Import URL',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Public http(s) link to a document.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.mute,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.url,
                autofocus: true,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.ink,
                ),
                decoration: InputDecoration(
                  hintText: 'https://…',
                  hintStyle:
                      GoogleFonts.plusJakartaSans(color: AppColors.mute),
                  filled: true,
                  fillColor: AppColors.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.field),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AuthPrimaryButton(
                label: 'Import',
                showArrow: true,
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
        url: url,
      );
    });
  }

  Future<void> _proceed() async {
    final upload = _pending;
    if (upload == null || _uploading) return;
    setState(() => _uploading = true);
    try {
      final country = await SessionPrefs.countryCode();
      final state = await SessionPrefs.stateRegion();
      final repo = DocumentsRepository();
      late final dynamic result;
      switch (upload.source) {
        case UploadSource.file:
        case UploadSource.scan:
          final bytes = upload.bytes;
          if (bytes == null) {
            _toast('Missing file data — pick again');
            return;
          }
          result = await repo.uploadFile(
            filename: upload.title,
            bytes: Uint8List.fromList(bytes),
            sourceType:
                upload.source == UploadSource.scan ? 'scan' : 'file',
            countryCode: country,
            stateCode: state,
          );
        case UploadSource.paste:
          result = await repo.uploadPaste(
            text: upload.text ?? '',
            title: upload.title,
            countryCode: country,
            stateCode: state,
          );
        case UploadSource.url:
          result = await repo.uploadUrl(
            url: upload.url ?? '',
            title: upload.title,
            countryCode: country,
            stateCode: state,
          );
      }
      if (!mounted) return;
      final withId = upload.copyWith(documentId: result.documentId as int);
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProcessingPage(upload: withId),
        ),
      );
    } on ApiException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: AppColors.ink,
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

  IconData _sourceIcon(UploadSource source) {
    return switch (source) {
      UploadSource.file => Icons.insert_drive_file_outlined,
      UploadSource.scan => Icons.document_scanner_outlined,
      UploadSource.paste => Icons.content_paste_rounded,
      UploadSource.url => Icons.link_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    _ensureEnter();
    final pending = _pending;

    return ColoredBox(
      color: AppColors.bg,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 8, 20, AppInsets.shellBottom(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeTransition(
                opacity: _fade(0.0, 0.35),
                child: SlideTransition(
                  position: _slide(0.0, 0.35),
                  child: const AppPageHeader(
                    title: 'Upload',
                    subtitle: 'Add a contract for review',
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              FadeTransition(
                opacity: _fade(0.12, 0.5),
                child: SlideTransition(
                  position: _slide(0.12, 0.5),
                  child: AnimatedScale(
                    scale: _heroPressed ? 0.97 : 1,
                    duration: const Duration(milliseconds: 140),
                    curve: Curves.easeOut,
                    child: _DropHero(
                      onTapDown: () => setState(() => _heroPressed = true),
                      onTapUp: () => setState(() => _heroPressed = false),
                      onTapCancel: () => setState(() => _heroPressed = false),
                      onTap: _pickFile,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FadeTransition(
                opacity: _fade(0.28, 0.65),
                child: SlideTransition(
                  position: _slide(0.28, 0.65),
                  child: Text(
                    'Or continue with',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mute,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FadeTransition(
                opacity: _fade(0.34, 0.75),
                child: SlideTransition(
                  position: _slide(0.34, 0.75),
                  child: Row(
                    children: [
                      Expanded(
                        child: _MethodPill(
                          icon: Icons.document_scanner_outlined,
                          label: 'Scan',
                          selected: pending?.source == UploadSource.scan,
                          onTap: _scanDocument,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MethodPill(
                          icon: Icons.content_paste_rounded,
                          label: 'Paste',
                          selected: pending?.source == UploadSource.paste,
                          onTap: _pasteText,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MethodPill(
                          icon: Icons.link_rounded,
                          label: 'URL',
                          selected: pending?.source == UploadSource.url,
                          onTap: _importUrl,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: pending == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey(pending.title),
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 380),
                          curve: Curves.easeOutCubic,
                          builder: (context, t, child) {
                            return Opacity(
                              opacity: t,
                              child: Transform.translate(
                                offset: Offset(0, 12 * (1 - t)),
                                child: child,
                              ),
                            );
                          },
                          child: _PendingCard(
                            title: pending.title,
                            detail: pending.detail,
                            sourceLabel: pending.sourceLabel,
                            icon: _sourceIcon(pending.source),
                            onClear: () => setState(() => _pending = null),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              FadeTransition(
                opacity: _fade(0.5, 0.9),
                child: SlideTransition(
                  position: _slide(0.5, 0.9),
                  child: const _TrustStrip(),
                ),
              ),
              const SizedBox(height: 16),
              FadeTransition(
                opacity: _fade(0.58, 1.0),
                child: SlideTransition(
                  position: _slide(0.58, 1.0),
                  child: AnimatedOpacity(
                    opacity: pending == null ? 0.55 : 1,
                    duration: const Duration(milliseconds: 240),
                    child: AuthPrimaryButton(
                      label: 'Proceed',
                      showArrow: true,
                      loading: _uploading,
                      onPressed: pending == null || _uploading ? null : _proceed,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DropHero extends StatelessWidget {
  const _DropHero({
    required this.onTap,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
  });

  final VoidCallback onTap;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onTap,
        onTapDown: (_) => onTapDown(),
        onTapUp: (_) => onTapUp(),
        onTapCancel: onTapCancel,
        child: Ink(
          height: 228,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2C2C2C),
                Color(0xFF1A1A1A),
                Color(0xFF3A3A3A),
              ],
            ),
            boxShadow: AppShadows.card,
          ),
          child: Stack(
            children: [
              Positioned(
                top: -36,
                right: -28,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Positioned(
                bottom: -40,
                left: -24,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.045),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.cloud_upload_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Choose a file',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PDF, DOC, DOCX, TXT  ·  max 10 MB',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.62),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Browse files',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: AppColors.ink,
                          ),
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
}

class _MethodPill extends StatelessWidget {
  const _MethodPill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: selected ? AppColors.ink : Colors.transparent,
              width: 1.6,
            ),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected ? AppColors.ink : AppColors.chip,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: selected ? AppColors.surface : AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.title,
    required this.detail,
    required this.sourceLabel,
    required this.icon,
    required this.onClear,
  });

  final String title;
  final String? detail;
  final String sourceLabel;
  final IconData icon;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.chip,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.ink, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    sourceLabel,
                    if (detail != null) detail!,
                  ].join('  ·  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.mute,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded),
            color: AppColors.mute,
          ),
        ],
      ),
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          _TrustRow(
            icon: Icons.sd_storage_outlined,
            text: 'Max file size: 10 MB',
          ),
          const SizedBox(height: 10),
          _TrustRow(
            icon: Icons.description_outlined,
            text: 'Supported: PDF, DOC, DOCX, TXT',
          ),
          const SizedBox(height: 10),
          _TrustRow(
            icon: Icons.lock_outline_rounded,
            text:
                'Your document is encrypted and auto-deleted after processing',
          ),
        ],
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.mute),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              height: 1.4,
              color: AppColors.mute,
            ),
          ),
        ),
      ],
    );
  }
}
