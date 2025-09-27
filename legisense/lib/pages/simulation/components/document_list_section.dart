import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../documents/components/components.dart';
import '../enhanced_simulation_details.dart';
import '../../../api/parsed_documents_repository.dart';
import 'styles.dart';

class DocumentListSection extends StatefulWidget {
  final Function(String documentId, String documentTitle)? onDocumentTap; // legacy single-tap (kept for compatibility)
  final Function(String documentId, String documentTitle)? onSimulate;

  const DocumentListSection({
    super.key,
    this.onDocumentTap,
    this.onSimulate,
  });

  @override
  State<DocumentListSection> createState() => _DocumentListSectionState();
}

class _DocumentListSectionState extends State<DocumentListSection> {
  String _searchQuery = '';
  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = true;
  String? _error;
  ParsedDocumentsRepository? _repo;

  @override
  void initState() {
    super.initState();
    _repo = ParsedDocumentsRepository(baseUrl: ApiConfig.baseUrl);
    _loadDocuments();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Called when the page becomes visible again
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh documents when page becomes visible (useful after navigation)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _repo != null) {
        _loadDocuments();
      }
    });
  }

  /// Ensure repository is initialized
  void _ensureRepositoryInitialized() {
    if (_repo == null) {
      _repo = ParsedDocumentsRepository(baseUrl: ApiConfig.baseUrl);
    }
  }

  Future<void> _loadDocuments() async {
    // Ensure repository is initialized
    _ensureRepositoryInitialized();

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final documents = await _repo!.fetchDocuments();
      if (mounted) {
        setState(() {
          _documents = documents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Manually refresh the documents list
  void refreshDocuments() {
    _loadDocuments();
  }

  /// Force UI update with current data
  void forceUIUpdate() {
    if (mounted) {
      setState(() {
        // Trigger rebuild
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM, vertical: AppTheme.spacingS),
      decoration: SimStyles.sectionDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: ListHeader(title: 'Document List')),
              IconButton(
                onPressed: _loadDocuments,
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: 'Refresh documents',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF3F4F6),
                  foregroundColor: const Color(0xFF6B7280),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: SearchField(
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          
          // Document count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '${_documents.length} document${_documents.length == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          
          // Server-backed list (natural height within parent scroll)
          Builder(
            builder: (context) {
              if (_isLoading) {
                return const _LoadingListSkeleton();
              }
              if (_error != null) {
                return _ErrorCard(error: _error!);
              }
              
              List<Map<String, dynamic>> list = _documents;
              final String q = _searchQuery.trim().toLowerCase();
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
                key: ValueKey('simulation_documents_list_${_documents.length}'),
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
                            children: [
                              // Show simulation count if available
                              Expanded(
                                child: FutureBuilder<Map<String, dynamic>>(
                                  future: _repo!.checkDocumentSimulations(documentId: id),
                                  builder: (context, snapshot) {
                                    final int simulationCount = snapshot.data?['simulation_count'] ?? 0;
                                    if (simulationCount > 0) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: SimStyles.badgeDecoration(const Color(0xFF10B981)),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.analytics, size: 14, color: Color(0xFF10B981)),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                '$simulationCount simulation${simulationCount == 1 ? '' : 's'}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF10B981),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              FutureBuilder<Map<String, dynamic>>(
                                future: _repo!.checkDocumentSimulations(documentId: id),
                                builder: (context, snapshot) {
                                  final bool hasSimulations = snapshot.data?['has_simulations'] == true;
                                  
                                  return ConstrainedBox(
                                    constraints: const BoxConstraints(minWidth: 120),
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        // Trigger backend simulation and show beautiful loader
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (_) => _buildBeautifulLoader(context, "Loading simulation..."),
                                        );
                                        try {
                                          // Step 1: Trigger simulation (may return cached or new data)
                                          final result = await _repo!.simulateDocument(id: id);
                                          if (!context.mounted) return;
                                          
                                          // Check if this was a cached simulation
                                          final bool isCached = result['cached'] == true;
                                          final String message = result['message'] ?? '';
                                          
                                          // Step 2: Fetch the simulation data
                                          final sessionId = result['session_id'] as int;
                                          final simulationData = await _repo!.fetchSimulationData(sessionId: sessionId);
                                          
                                          if (!context.mounted) return;
                                          Navigator.of(context).pop(); // close loader
                                          
                                          // Show appropriate message based on cache status
                                          if (isCached) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Row(
                                                  children: [
                                                    const Icon(Icons.cached, color: Colors.white, size: 20),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        'Using existing simulation: $message',
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                backgroundColor: const Color(0xFF10B981),
                                                duration: const Duration(seconds: 3),
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Row(
                                                  children: [
                                                    const Icon(Icons.analytics, color: Colors.white, size: 20),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        'New simulation generated: $message',
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                backgroundColor: const Color(0xFF6366F1),
                                                duration: const Duration(seconds: 3),
                                              ),
                                            );
                                          }
                                          
                                          // Step 3: Navigate to enhanced page with real data
                                          if (widget.onSimulate != null) {
                                            widget.onSimulate!("server-$id", title);
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
                                      icon: Icon(
                                        hasSimulations ? Icons.cached : Icons.play_arrow_rounded, 
                                        size: 18
                                      ),
                                      label: Text(hasSimulations ? 'View Simulation' : 'Simulate'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: hasSimulations 
                                          ? const Color(0xFF10B981) 
                                          : const Color(0xFF6366F1),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  );
                                },
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

  Widget _buildBeautifulLoader(BuildContext context, [String? customMessage]) {
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
              customMessage ?? 'Generating Simulation',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            
            // Subtitle
            Text(
              customMessage != null 
                ? 'Checking for existing data or generating new simulation...'
                : 'Analyzing document and creating realistic scenarios...',
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
