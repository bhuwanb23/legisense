import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_theme.dart';
import '../../../api/parsed_documents_repository.dart';
import '../../../main.dart';
import '../../documents/document_view_detail.dart';

class RecentFiles extends StatefulWidget {
  const RecentFiles({super.key});

  @override
  State<RecentFiles> createState() => _RecentFilesState();
}

class _RecentFilesState extends State<RecentFiles> {
  List<Map<String, dynamic>> recentFiles = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadRecentFiles();
  }

  Future<void> _loadRecentFiles() async {
    // Try different possible backend URLs (prioritize Android emulator)
    List<String> possibleUrls = [
      'http://10.0.2.2:8000', // Android emulator (try this first)
      'http://localhost:8000',
      'http://127.0.0.1:8000',
    ];
    
    String? lastError;
    
    for (String baseUrl in possibleUrls) {
      try {
        setState(() {
          isLoading = true;
          error = null;
        });

        print('DEBUG: Trying to connect to $baseUrl');
        final repository = ParsedDocumentsRepository(baseUrl: baseUrl);
        final documents = await repository.fetchDocuments();
        
        print('DEBUG: Successfully connected to $baseUrl');
        print('DEBUG: Fetched ${documents.length} documents');
        print('DEBUG: Documents: $documents');
        
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
        print('DEBUG: Failed to connect to $baseUrl: $e');
        lastError = 'Failed to connect to $baseUrl: ${e.toString()}';
        continue; // Try next URL
      }
    }
    
    // If we get here, all URLs failed
    print('DEBUG: All connection attempts failed');
    setState(() {
      error = 'Could not connect to backend server.\nTried: ${possibleUrls.join(', ')}\nLast error: $lastError\n\nPlease ensure the Django server is running on your computer.';
      isLoading = false;
    });
  }

  String _formatTimeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else {
        return 'just now';
      }
    } catch (e) {
      return 'recently';
    }
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingS + 6, vertical: AppTheme.spacingS + 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Files',
                style: AppTheme.heading4,
              )
                  .animate()
                  .slideY(
                    begin: 0.3,
                    duration: AppTheme.animationMedium,
                    curve: Curves.easeOut,
                  )
                  .fadeIn(duration: AppTheme.animationSlow, delay: 200.ms),
              
              if (recentFiles.isNotEmpty)
                TextButton(
                  onPressed: () {
                    navigateToPage(1); // Navigate to Documents page
                  },
                  child: Text(
                    'View All',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingS + 6),
          
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
                padding: const EdgeInsets.only(bottom: AppTheme.spacingS + 6),
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
        padding: const EdgeInsets.all(AppTheme.spacingS + 6),
        decoration: BoxDecoration(
          color: AppTheme.backgroundWhite.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
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
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Icon(
                icon,
                color: color,
                size: 18,
              ),
            ),
            
            const SizedBox(width: AppTheme.spacingM),
            
            // File Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    subtitle,
                    style: AppTheme.bodySmall,
                  ),
                ],
              ),
            ),
            
            // More Options Button
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: Builder(
                builder: (context) => IconButton(
                onPressed: () {
                  _showFileOptions(context, id, title);
                },
                icon: const Icon(
                  FontAwesomeIcons.ellipsisVertical,
                  color: AppTheme.textTertiary,
                  size: 14,
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
        )
        .fadeIn(duration: AppTheme.animationSlow, delay: delay.ms);
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
            'Failed to load recent files',
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
            child: const Text('Retry'),
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
            'No recent files',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textTertiary),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            'Upload your first document to get started',
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
              title: const Text('View Document'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DocumentViewDetail(
                      title: title,
                      meta: 'PDF Document',
                      docId: 'server-$id',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(FontAwesomeIcons.chartLine),
              title: const Text('View Analysis'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DocumentViewDetail(
                      title: title,
                      meta: 'PDF Document',
                      docId: 'server-$id',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(FontAwesomeIcons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share functionality coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
