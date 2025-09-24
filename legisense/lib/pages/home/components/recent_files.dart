import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import '../../../utils/refresh_bus.dart';
import '../../../theme/app_theme.dart';
import '../../../api/parsed_documents_repository.dart';
import '../../../utils/responsive.dart';
import '../../../main.dart';
import '../../documents/document_view_detail.dart';
import '../../profile/language/language_scope.dart';
import '../language/strings.dart';

class RecentFiles extends StatefulWidget {
  const RecentFiles({super.key});

  @override
  State<RecentFiles> createState() => _RecentFilesState();
}

class _RecentFilesState extends State<RecentFiles> {
  List<Map<String, dynamic>> recentFiles = [];
  bool isLoading = true;
  String? error;
  late final VoidCallback _busListener;

  @override
  void initState() {
    super.initState();
    _loadRecentFiles();
    // refresh when bus pings (e.g., after upload)
    _busListener = () { if (mounted) _loadRecentFiles(); };
    GlobalRefreshBus.notifier.addListener(_busListener);
  }

  Future<void> _loadRecentFiles() async {
    // Use fixed Wi‑Fi IP as the backend base URL
    List<String> possibleUrls = [ApiConfig.baseUrl];
    
    String? lastError;
    
    for (String baseUrl in possibleUrls) {
      try {
        setState(() {
          isLoading = true;
          error = null;
        });

        debugPrint('DEBUG: Trying to connect to $baseUrl');
        final repository = ParsedDocumentsRepository(baseUrl: baseUrl);
        final documents = await repository.fetchDocuments();
        
        debugPrint('DEBUG: Successfully connected to $baseUrl');
        debugPrint('DEBUG: Fetched ${documents.length} documents');
        debugPrint('DEBUG: Documents: $documents');
        
        // Convert to display format and take only recent 3
        final files = documents.take(3).map((doc) {
          final fileName = doc['file_name']?.toString() ?? 'Unknown Document';
          final createdAt = doc['created_at']?.toString() ?? '';
          final fileExtension = fileName.split('.').last.toLowerCase();
          
          // Determine icon and colors based on file type
          IconData icon;
          Color color;
          Color bgColor;
          
          switch (fileExtension) {
            case 'pdf':
              icon = FontAwesomeIcons.filePdf;
              color = const Color(0xFFEF4444);
              bgColor = const Color(0xFFFEE2E2);
              break;
            case 'doc':
            case 'docx':
              icon = FontAwesomeIcons.fileWord;
              color = const Color(0xFF2563EB);
              bgColor = const Color(0xFFDBEAFE);
              break;
            default:
              icon = FontAwesomeIcons.file;
              color = const Color(0xFF6B7280);
              bgColor = const Color(0xFFF3F4F6);
          }
          
          // Format time ago
          String timeAgo = _formatTimeAgo(createdAt);
          
          return {
            'id': doc['id'],
            'title': fileName,
            'subtitle': 'Uploaded $timeAgo',
            'icon': icon,
            'color': color,
            'bgColor': bgColor,
          };
        }).toList();

        setState(() {
          recentFiles = files;
          isLoading = false;
        });
        return; // Success, exit the loop
      } catch (e) {
        debugPrint('DEBUG: Failed to connect to $baseUrl: $e');
        lastError = 'Failed to connect to $baseUrl: ${e.toString()}';
        continue; // Try next URL
      }
    }
    
    // If we get here, all URLs failed
    debugPrint('DEBUG: All connection attempts failed');
    setState(() {
      error = 'Could not connect to backend server.\nTried: ${possibleUrls.join(', ')}\nLast error: $lastError\n\nPlease ensure the Django server is running on your computer.';
      isLoading = false;
    });
  }

  @override
  void dispose() {
    GlobalRefreshBus.notifier.removeListener(_busListener);
    super.dispose();
  }

  String _formatTimeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      final controller = LanguageScope.maybeOf(context);
      final i18n = HomeI18n.mapFor(controller?.language ?? AppLanguage.en);
      if (difference.inDays > 0) {
        final n = difference.inDays;
        return '$n ${n == 1 ? (i18n['recent.day'] ?? 'day') : (i18n['recent.days'] ?? 'days')} ${i18n['recent.ago'] ?? 'ago'}';
      } else if (difference.inHours > 0) {
        final n = difference.inHours;
        return '$n ${n == 1 ? (i18n['recent.hour'] ?? 'hour') : (i18n['recent.hours'] ?? 'hours')} ${i18n['recent.ago'] ?? 'ago'}';
      } else if (difference.inMinutes > 0) {
        final n = difference.inMinutes;
        return '$n ${n == 1 ? (i18n['recent.minute'] ?? 'minute') : (i18n['recent.minutes'] ?? 'minutes')} ${i18n['recent.ago'] ?? 'ago'}';
      } else {
        return i18n['recent.justNow'] ?? 'just now';
      }
    } catch (e) {
      final controller = LanguageScope.maybeOf(context);
      final i18n = HomeI18n.mapFor(controller?.language ?? AppLanguage.en);
      return i18n['recent.recently'] ?? 'recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = LanguageScope.maybeOf(context);
    final i18n = HomeI18n.mapFor(controller?.language ?? AppLanguage.en);
    final isSmall = ResponsiveHelper.isSmallScreen(context);
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  i18n['recent.title'] ?? 'Recent Files',
                  style: AppTheme.heading4,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
                    .animate()
                    .slideY(
                      begin: 0.3,
                      duration: AppTheme.animationMedium,
                      curve: Curves.easeOut,
                    ),
              ),
              if (recentFiles.isNotEmpty)
                TextButton(
                  onPressed: () {
                    navigateToPage(1); // Navigate to Documents page
                  },
                  child: Text(
                    i18n['recent.viewAll'] ?? 'View All',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          
          SizedBox(height: isSmall ? AppTheme.spacingXS : AppTheme.spacingS),
          
          if (isLoading)
            _buildLoadingState()
          else if (error != null)
            _buildErrorState()
          else if (recentFiles.isEmpty)
            _buildEmptyState()
          else
            ...recentFiles.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> file = entry.value;
              
              return Padding(
                padding: EdgeInsets.only(
                  bottom: isSmall ? AppTheme.spacingXS : AppTheme.spacingS,
                ),
                child: _buildFileCard(
                  context: context,
                  id: file['id'],
                  title: file['title'],
                  subtitle: file['subtitle'],
                  icon: file['icon'],
                  color: file['color'],
                  bgColor: file['bgColor'],
                  delay: 400 + (index * 200),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildFileCard({
    required BuildContext context,
    required int id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required int delay,
  }) {
    final isSmall = ResponsiveHelper.isSmallScreen(context);
    return GestureDetector(
      onTap: () {
        // Navigate to document detail page
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DocumentViewDetail(
              title: title,
              meta: subtitle,
              docId: 'server-$id',
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(isSmall ? AppTheme.spacingXS + 2 : AppTheme.spacingS),
        decoration: BoxDecoration(
          color: AppTheme.backgroundWhite.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(isSmall ? AppTheme.radiusS : AppTheme.radiusM),
          border: Border.all(
            color: AppTheme.backgroundWhite.withValues(alpha: 0.2),
            width: 1,
          ),
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
            // File Icon
            Container(
              width: isSmall ? 32 : 40,
              height: isSmall ? 32 : 40,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(isSmall ? AppTheme.radiusS : AppTheme.radiusM),
              ),
              child: Icon(
                icon,
                color: color,
                size: isSmall ? 14 : 16,
              ),
            ),
            
            SizedBox(width: isSmall ? AppTheme.spacingXS : AppTheme.spacingS),
            
            // File Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: isSmall ? AppTheme.bodySmall : AppTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isSmall ? AppTheme.spacingXS - 3 : AppTheme.spacingXS - 2),
                  Text(
                    subtitle,
                    style: AppTheme.bodySmall,
                  ),
                ],
              ),
            ),
            
            // More Options Button
            Container(
              width: isSmall ? 22 : 26,
              height: isSmall ? 22 : 26,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(isSmall ? AppTheme.radiusS : AppTheme.radiusS),
              ),
              child: Builder(
                builder: (context) => IconButton(
                onPressed: () {
                  _showFileOptions(context, id, title);
                },
                icon: const Icon(
                  FontAwesomeIcons.ellipsisVertical,
                  color: AppTheme.textTertiary,
                  size: 13,
                ),
                padding: EdgeInsets.zero,
              ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .slideX(
          begin: 0.3,
          duration: AppTheme.animationMedium,
          curve: Curves.easeOut,
        );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        children: [
          Icon(
            FontAwesomeIcons.triangleExclamation,
            color: AppTheme.errorRed,
            size: 24,
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            HomeI18n.mapFor(LanguageScope.maybeOf(context)?.language ?? AppLanguage.en)['recent.failed'] ?? 'Failed to load recent files',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorRed),
          ),
          if (error != null) ...[
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              error!,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.errorRed),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppTheme.spacingS),
          ElevatedButton(
            onPressed: _loadRecentFiles,
            child: Text(HomeI18n.mapFor(LanguageScope.maybeOf(context)?.language ?? AppLanguage.en)['recent.retry'] ?? 'Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        children: [
          Icon(
            FontAwesomeIcons.folderOpen,
            color: AppTheme.textTertiary,
            size: 32,
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            HomeI18n.mapFor(LanguageScope.maybeOf(context)?.language ?? AppLanguage.en)['recent.emptyTitle'] ?? 'No recent files',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textTertiary),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            HomeI18n.mapFor(LanguageScope.maybeOf(context)?.language ?? AppLanguage.en)['recent.emptySubtitle'] ?? 'Upload your first document to get started',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showFileOptions(BuildContext context, int id, String title) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: AppTheme.heading4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingM),
            ListTile(
              leading: const Icon(FontAwesomeIcons.eye),
              title: Text(HomeI18n.mapFor(LanguageScope.maybeOf(context)?.language ?? AppLanguage.en)['sheet.viewDoc'] ?? 'View Document'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DocumentViewDetail(
                      title: title,
                      meta: HomeI18n.mapFor(LanguageScope.maybeOf(context)?.language ?? AppLanguage.en)['meta.pdf'] ?? 'PDF Document',
                      docId: 'server-$id',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(FontAwesomeIcons.chartLine),
              title: Text(HomeI18n.mapFor(LanguageScope.maybeOf(context)?.language ?? AppLanguage.en)['sheet.viewAnalysis'] ?? 'View Analysis'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DocumentViewDetail(
                      title: title,
                      meta: HomeI18n.mapFor(LanguageScope.maybeOf(context)?.language ?? AppLanguage.en)['meta.pdf'] ?? 'PDF Document',
                      docId: 'server-$id',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(FontAwesomeIcons.share),
              title: Text(HomeI18n.mapFor(LanguageScope.maybeOf(context)?.language ?? AppLanguage.en)['sheet.share'] ?? 'Share'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Share functionality coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
