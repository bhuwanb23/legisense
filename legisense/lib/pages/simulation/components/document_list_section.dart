import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../documents/components/components.dart';
import '../../documents/document_view_detail.dart';
import '../enhanced_simulation_details.dart';
import '../../../api/parsed_documents_repository.dart';

class DocumentListSection extends StatelessWidget {
  final Function(String documentId, String documentTitle)? onDocumentTap; // legacy single-tap (kept for compatibility)
  final Function(String documentId, String documentTitle)? onSimulate;
  final Function(String documentId, String documentTitle)? onViewDetails;
  final String searchQuery;
  
  const DocumentListSection({
    super.key,
    this.onDocumentTap,
    this.onSimulate,
    this.onViewDetails,
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
                              OutlinedButton.icon(
                                onPressed: () {
                                  if (onViewDetails != null) {
                                    onViewDetails!("server-$id", title);
                                  } else {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => DocumentViewDetail(
                                          title: title,
                                          meta: meta,
                                          docId: 'server-$id',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.description, size: 16),
                                label: const Text('Details'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  // Trigger backend simulation and show loader while waiting
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => const Center(child: CircularProgressIndicator()),
                                  );
                                  try {
                                    final result = await repo.simulateDocument(id: id);
                                    if (!context.mounted) return;
                                    Navigator.of(context).pop(); // close loader
                                    // After successful simulation, either use callback or default navigation
                                    if (onSimulate != null) {
                                      onSimulate!("server-$id", title);
                                    } else {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => EnhancedSimulationDetailsPage(
                                            documentId: "server-$id",
                                            documentTitle: title,
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    Navigator.of(context).pop(); // close loader
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Simulation failed: $e')),
                                    );
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
