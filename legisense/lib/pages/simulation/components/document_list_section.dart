import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../documents/components/components.dart';
import '../enhanced_simulation_details.dart';
import '../../../api/parsed_documents_repository.dart';

class DocumentListSection extends StatelessWidget {
  final Function(String documentId, String documentTitle)? onDocumentTap; // legacy single-tap (kept for compatibility)
  final Function(String documentId, String documentTitle)? onSimulate;
  final String searchQuery;
  
  const DocumentListSection({
    super.key,
    this.onDocumentTap,
    this.onSimulate,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    final repo = ParsedDocumentsRepository(baseUrl: const String.fromEnvironment('LEGISENSE_API_BASE', defaultValue: 'http://10.0.2.2:8000'));
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM, vertical: AppTheme.spacingS),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 1.0),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ListHeader(title: 'Document List'),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          // Match documents page: server-backed list (natural height within parent scroll)
          FutureBuilder<List<Map<String, dynamic>>>(
            future: repo.fetchDocuments(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const _LoadingListSkeleton();
              }
              if (snapshot.hasError) {
                return _ErrorCard(error: snapshot.error.toString());
              }
              List<Map<String, dynamic>> list = (snapshot.data ?? const <Map<String, dynamic>>[]);
              final String q = searchQuery.trim().toLowerCase();
              if (q.isNotEmpty) {
                list = list.where((e) {
                  final name = (e['file_name'] ?? '').toString().toLowerCase();
                  return name.contains(q);
                }).toList();
              }
              if (list.isEmpty) {
                return const _EmptyStateCard();
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                itemBuilder: (context, index) {
                  final item = list[index];
                  final String title = (item['file_name'] ?? 'Document').toString();
                  final int pages = (item['num_pages'] ?? 0) as int;
                  final String meta = 'PDF • $pages page${pages == 1 ? '' : 's'}';
                  final int id = (item['id'] as int);
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 300 + index * 60),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - value) * 12),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // keep visual list item but disable navigation semantics by making onTap a no-op
                        DocumentListItem(
                          title: title,
                          meta: meta,
                          onTap: () {},
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  // Trigger backend simulation and show beautiful loader
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => _buildBeautifulLoader(context),
                                  );
                                  try {
                                    // Step 1: Trigger simulation
                                    final result = await repo.simulateDocument(id: id);
                                    if (!context.mounted) return;
                                    
                                    // Step 2: Fetch the generated simulation data
                                    final sessionId = result['session_id'] as int;
                                    final simulationData = await repo.fetchSimulationData(sessionId: sessionId);
                                    
                                    if (!context.mounted) return;
                                    Navigator.of(context).pop(); // close loader
                                    
                                    // Step 3: Navigate to enhanced page with real data
                                    if (onSimulate != null) {
                                      onSimulate!("server-$id", title);
                                    } else {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => EnhancedSimulationDetailsPage(
                                            documentId: "server-$id",
                                            documentTitle: title,
                                            simulationData: simulationData,
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    Navigator.of(context).pop(); // close loader
                                    _showErrorDialog(context, e.toString());
                                  }
                                },
                                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                                label: const Text('Simulate'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBeautifulLoader(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 2),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6366F1),
                          const Color(0xFF8B5CF6),
                          const Color(0xFFEC4899),
                        ],
                        stops: [0.0, 0.5, 1.0],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.analytics_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Generating Simulation',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            
            // Subtitle
            Text(
              'Analyzing document and creating realistic scenarios...',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 32),
            
            // Animated progress indicator
            SizedBox(
              width: 200,
              child: Column(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(seconds: 3),
                    builder: (context, value, child) {
                      return LinearProgressIndicator(
                        value: value,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFF6366F1),
                        ),
                        borderRadius: BorderRadius.circular(10),
                        minHeight: 8,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Animated dots
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(seconds: 1),
                    builder: (context, value, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          final delay = index * 0.2;
                          final animationValue = (value - delay).clamp(0.0, 1.0);
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: Transform.scale(
                              scale: 0.5 + (0.5 * animationValue),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFDC2626),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Simulation Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unable to generate simulation data. This could be due to:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            const Text('• Network connectivity issues'),
            const Text('• Server processing error'),
            const Text('• Document analysis failure'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                error,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Retry simulation
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// Local copies of list UI helpers to match documents page
class _LoadingListSkeleton extends StatefulWidget {
  const _LoadingListSkeleton();

  @override
  State<_LoadingListSkeleton> createState() => _LoadingListSkeletonState();
}

class _LoadingListSkeletonState extends State<_LoadingListSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _pulse = Tween(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
      itemBuilder: (context, index) {
        return FadeTransition(
          opacity: _pulse,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: const [
                _SkeletonBox(width: 36, height: 36, radius: 8),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBox(width: 160, height: 12, radius: 6),
                      SizedBox(height: 6),
                      _SkeletonBox(width: 100, height: 10, radius: 6),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.width, required this.height, required this.radius});
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.inbox_rounded, color: Color(0xFF64748B)),
            SizedBox(width: 8),
            Text('No documents uploaded yet', style: TextStyle(color: Color(0xFF334155))),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Failed to load documents: $error',
                style: const TextStyle(color: Color(0xFF991B1B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
