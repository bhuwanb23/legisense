import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../api/parsed_documents_repository.dart';
import '../../documents/documents_page.dart';
import '../../documents/data/sample_documents.dart';
import '../../../theme/app_theme.dart';

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

  @override
  void initState() {
    super.initState();
    // TODO: Replace with your backend base URL
    final String base = _apiBaseOverride ?? const String.fromEnvironment('LEGISENSE_API_BASE', defaultValue: 'http://10.0.2.2:8000');
    _repo = ParsedDocumentsRepository(baseUrl: base);
  }
  Future<void> _pickDocument() async {
    try {
      setState(() {
        _isLoading = true;
        _loadingLabel = 'Opening picker...';
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

      if (selectedFile != null || (result != null && result.files.isNotEmpty)) {
        if (selectedFile == null) {
          final PlatformFile file = result!.files.single;
          if (file.extension?.toLowerCase() != 'pdf') {
            _showErrorDialog('Only PDF is supported for parsing at the moment.');
            return;
          }
          final String? path = file.path;
          if (path == null) {
            _showErrorDialog('File path unavailable.');
            return;
          }
          selectedFile = File(path);
        }

        // Ensure extension is PDF for backend parsing
        final String lower = selectedFile!.path.toLowerCase();
        if (!lower.endsWith('.pdf')) {
          _showErrorDialog('Only PDF is supported for parsing at the moment.');
          return;
        }
        setState(() {
          _loadingLabel = 'Uploading...';
        });
        final parsed = await _repo.uploadAndParsePdf(pdfFile: selectedFile!);
        // Also reflect in global uploaded list for documents page
        kUploadedDocuments.insert(0, parsed);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF processed successfully'),
            backgroundColor: AppTheme.successGreen,
            duration: Duration(seconds: 2),
          ),
        );
        // Navigate to documents page to view it
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DocumentsPage()),
        );
      }
    } catch (e) {
      _showConnectivityHelp('Failed to pick document: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _loadingLabel = 'Opening picker...';
      });
    }
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

  void _showConnectivityHelp(String message) {
    final TextEditingController controller = TextEditingController(text: _repo.baseUrl);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Connection problem'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$message\n\nCurrent base URL: ${_repo.baseUrl}'),
                const SizedBox(height: 12),
                const Text('Quick fixes:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _retryWithBase('http://10.0.2.2:8000');
                      },
                      child: const Text('Use 10.0.2.2'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _retryWithBase('http://127.0.0.1:8000');
                      },
                      child: const Text('Use 127.0.0.1'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Custom base URL (e.g., http://192.168.x.y:8000):'),
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
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final String value = controller.text.trim();
                Navigator.of(context).pop();
                _retryWithBase(value);
              },
              child: const Text('Retry with URL'),
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
                                _loadingLabel,
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
