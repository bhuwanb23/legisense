import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:async';
import '../../../api/parsed_documents_repository.dart';
import '../../documents/documents_page.dart';
import '../../documents/data/sample_documents.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/responsive.dart';
import '../../profile/language/language_scope.dart';
import '../language/strings.dart';

class UploadZone extends StatefulWidget {
  const UploadZone({super.key});

  @override
  State<UploadZone> createState() => _UploadZoneState();
}

class _UploadZoneState extends State<UploadZone> {
  final bool _isDragOver = false;
  bool _isLoading = false;
  late final ParsedDocumentsRepository _repo;
  String _loadingLabel = 'Opening picker...';
  String? _apiBaseOverride;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Use the same base URL configuration as the repository
    final String base = _apiBaseOverride ?? ApiConfig.baseUrl;
    _repo = ParsedDocumentsRepository(baseUrl: base);
    // Background refresh every 5 seconds to keep documents fresh
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        await _repo.fetchDocuments();
      } catch (_) {
        // ignore background refresh errors
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
  Future<void> _pickDocument() async {
    try {
      final lang = LanguageScope.maybeOf(context)?.language ?? AppLanguage.en;
      final i18n = HomeI18n.mapFor(lang);
      setState(() {
        _isLoading = true;
        _loadingLabel = i18n['upload.loading.openPicker'] ?? 'Opening picker...';
      });

      // Dev override: if a local Windows file exists at the given path, use it
      // immediately (useful when testing from emulator/device that can't reach
      // the PC file picker). If the file doesn't exist, fall back to picker.
      final String devPath = r'C:\Users\Bhuwan\Downloads\sample_text.pdf';
      File? selectedFile;
      if (File(devPath).existsSync()) {
        selectedFile = File(devPath);
      }

      final FilePickerResult? result = selectedFile == null
          ? await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'doc', 'docx', 'ppt', 'pptx'],
        withData: false,
        allowMultiple: false,
      )
          : null;
      if (!mounted) return;

      if (selectedFile != null || (result != null && result.files.isNotEmpty)) {
        if (selectedFile == null) {
          final PlatformFile file = result!.files.single;
          if (file.extension?.toLowerCase() != 'pdf') {
            final i18n = HomeI18n.mapFor(LanguageScope.maybeOf(context)?.language ?? AppLanguage.en);
            if (!mounted) return;
            _showErrorDialog(i18n['upload.error.onlyPdf'] ?? 'Only PDF is supported for parsing at the moment.');
            return;
          }
          final String? path = file.path;
          if (path == null) {
            final i18n = HomeI18n.mapFor(LanguageScope.maybeOf(context)?.language ?? AppLanguage.en);
            if (!mounted) return;
            _showErrorDialog(i18n['upload.error.pathUnavailable'] ?? 'File path unavailable.');
            return;
          }
          selectedFile = File(path);
        }

        // Ensure extension is PDF for backend parsing
        final String lower = selectedFile.path.toLowerCase();
        if (!lower.endsWith('.pdf')) {
          final i18n = HomeI18n.mapFor(LanguageScope.maybeOf(context)?.language ?? AppLanguage.en);
          if (!mounted) return;
          _showErrorDialog(i18n['upload.error.onlyPdf'] ?? 'Only PDF is supported for parsing at the moment.');
          return;
        }
        setState(() {
          final i18n = HomeI18n.mapFor(LanguageScope.maybeOf(context)?.language ?? AppLanguage.en);
          _loadingLabel = i18n['upload.loading.uploading'] ?? 'Uploading...';
        });
        final parsed = await _repo.uploadAndParsePdf(pdfFile: selectedFile);
        // Also reflect in global uploaded list for documents page
        kUploadedDocuments.insert(0, parsed);
        // Single-shot probe (do not poll): try once to warm cache; ignore failures
        try {
          final String idStr = parsed.id;
          if (idStr.startsWith('server-')) {
            final int serverId = int.parse(idStr.split('-').last);
            setState(() {
              final i18n = HomeI18n.mapFor(LanguageScope.maybeOf(context)?.language ?? AppLanguage.en);
              _loadingLabel = i18n['upload.loading.analyzing'] ?? 'Analyzing document...';
            });
            await _repo.fetchAnalysis(serverId);
            
            // Show translation progress (translations happen in background)
            setState(() {
              final i18n = HomeI18n.mapFor(LanguageScope.maybeOf(context)?.language ?? AppLanguage.en);
              _loadingLabel = i18n['upload.loading.translating'] ?? 'Preparing translations...';
            });
            // Small delay to show the message
            await Future.delayed(const Duration(milliseconds: 500));
          }
        } catch (_) {}
        if (!mounted) return;
        final i18n = HomeI18n.mapFor(LanguageScope.maybeOf(context)?.language ?? AppLanguage.en);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(i18n['upload.snackbar.success'] ?? 'PDF processed successfully. Translations are being prepared in the background.'),
            backgroundColor: AppTheme.successGreen,
            duration: const Duration(seconds: 3),
          ),
        );
        // Navigate to documents page to view it
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DocumentsPage()),
        );
      }
    } catch (e) {
      final i18n = HomeI18n.mapFor(LanguageScope.maybeOf(context)?.language ?? AppLanguage.en);
      if (mounted) {
        _showConnectivityHelp('${i18n['upload.error.failedPick'] ?? 'Failed to pick document'}: $e');
      }
    } finally {
      if (mounted) {
        final i18n = HomeI18n.mapFor(LanguageScope.maybeOf(context)?.language ?? AppLanguage.en);
        setState(() {
          _isLoading = false;
          _loadingLabel = i18n['upload.loading.openPicker'] ?? 'Opening picker...';
        });
      }
    }
  }

  

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
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

  void _showConnectivityHelp(String message) {
    final TextEditingController controller = TextEditingController(text: _repo.baseUrl);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final i18n = HomeI18n.mapFor(LanguageScope.maybeOf(context)?.language ?? AppLanguage.en);
        return AlertDialog(
          title: Text(i18n['upload.connect.title'] ?? 'Connection problem'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$message\n\nCurrent base URL: ${_repo.baseUrl}'),
                const SizedBox(height: 12),
                Text(i18n['upload.connect.quickFixes'] ?? 'Quick fixes:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _retryWithBase('http://10.0.2.2:8000');
                      },
                      child: Text(i18n['upload.connect.use10'] ?? 'Use 10.0.2.2'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _retryWithBase('http://127.0.0.1:8000');
                      },
                      child: Text(i18n['upload.connect.use127'] ?? 'Use 127.0.0.1'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _retryWithBase(ApiConfig.baseUrl);
                      },
                      child: Text(i18n['upload.connect.useDefault'] ?? 'Use Default'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(i18n['upload.connect.customLabel'] ?? 'Custom base URL (e.g., http://192.168.x.y:8000):'),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'http://192.168.x.y:8000'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(i18n['upload.connect.cancel'] ?? 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final String value = controller.text.trim();
                Navigator.of(context).pop();
                _retryWithBase(value);
              },
              child: Text(i18n['upload.connect.retry'] ?? 'Retry with URL'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _retryWithBase(String base) async {
    if (base.isEmpty) return;
    setState(() {
      _apiBaseOverride = base;
      _repo = ParsedDocumentsRepository(baseUrl: base);
    });
    await _pickDocument();
  }
  

  @override
  Widget build(BuildContext context) {
    final isSmall = ResponsiveHelper.isSmallScreen(context);
    final lang = LanguageScope.maybeOf(context)?.language ?? AppLanguage.en;
    final i18n = HomeI18n.mapFor(lang);
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getResponsivePadding(
          context,
          small: AppTheme.spacingS,
          medium: AppTheme.spacingS + 6,
          large: AppTheme.spacingM,
        ),
        vertical: ResponsiveHelper.getResponsivePadding(
          context,
          small: AppTheme.spacingS,
          medium: AppTheme.spacingS + 6,
          large: AppTheme.spacingM,
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(isSmall ? AppTheme.spacingS : AppTheme.spacingM - 2),
        decoration: BoxDecoration(
          color: AppTheme.backgroundWhite.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(isSmall ? AppTheme.radiusM : AppTheme.radiusL),
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
              width: isSmall ? 40 : 50,
              height: isSmall ? 40 : 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryBlueLight, AppTheme.primaryBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(isSmall ? 20 : 25),
              ),
              child: const Icon(
                FontAwesomeIcons.cloudArrowUp,
                color: Colors.white,
                size: 16,
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.8, 0.8),
                  duration: AppTheme.animationMedium,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: AppTheme.animationSlow, delay: 200.ms),
            
            SizedBox(height: isSmall ? AppTheme.spacingXS + 2 : AppTheme.spacingS),
            
            // Title and Description
            Text(
              i18n['upload.title'] ?? 'Upload a Document',
              style: AppTheme.heading4,
            )
                .animate()
                .slideY(
                  begin: 0.3,
                  duration: AppTheme.animationMedium,
                  curve: Curves.easeOut,
                )
                .fadeIn(duration: AppTheme.animationSlow, delay: 400.ms),
            
            SizedBox(height: isSmall ? AppTheme.spacingXS : AppTheme.spacingXS + 2),
            
            Text(
              i18n['upload.subtitle'] ?? 'Select a PDF, DOC/DOCX, or PPT/PPTX to process',
              style: AppTheme.bodySmall,
            )
                .animate()
                .slideY(
                  begin: 0.3,
                  duration: AppTheme.animationMedium,
                  curve: Curves.easeOut,
                )
                .fadeIn(duration: AppTheme.animationSlow, delay: 600.ms),
            
            SizedBox(height: isSmall ? AppTheme.spacingS : AppTheme.spacingM - 2),
            
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
                      padding: EdgeInsets.symmetric(
                        vertical: isSmall ? AppTheme.spacingS - 2 : AppTheme.spacingS + 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isSmall ? AppTheme.radiusS : AppTheme.radiusM),
                      ),
                      elevation: 8,
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: isSmall ? 12 : 14,
                                height: isSmall ? 12 : 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: isSmall ? AppTheme.spacingXS : AppTheme.spacingXS + 2),
                              Text(
                                _loadingLabel,
                                style: AppTheme.buttonPrimary,
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                FontAwesomeIcons.fileArrowUp,
                                size: isSmall ? 12 : 14,
                              ),
                              SizedBox(width: isSmall ? AppTheme.spacingXS : AppTheme.spacingXS + 2),
                              Text(
                                i18n['upload.button.upload'] ?? 'Upload Document',
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
                
                SizedBox(height: isSmall ? AppTheme.spacingXS + 2 : AppTheme.spacingS),
                
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
                      padding: EdgeInsets.symmetric(
                        vertical: isSmall ? AppTheme.spacingS : AppTheme.spacingS + 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isSmall ? AppTheme.radiusS : AppTheme.radiusM),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          FontAwesomeIcons.folderOpen,
                          size: isSmall ? 12 : 14,
                        ),
                        SizedBox(width: isSmall ? AppTheme.spacingXS : AppTheme.spacingS),
                        Text(
                          i18n['upload.button.browse'] ?? 'Browse Files',
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
