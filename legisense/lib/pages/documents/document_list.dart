import 'package:flutter/material.dart';
import 'document_view_detail.dart';
import 'components/components.dart';
import '../profile/language/language_scope.dart';
import 'language/strings.dart';
import '../../api/parsed_documents_repository.dart';

class DocumentListPanel extends StatefulWidget {
  const DocumentListPanel({super.key});

  @override
  State<DocumentListPanel> createState() => _DocumentListPanelState();
}

/// Controller for DocumentListPanel to allow external refresh
class DocumentListController {
  _DocumentListPanelState? _state;
  
  void _attach(_DocumentListPanelState state) {
    _state = state;
  }
  
  void _detach() {
    _state = null;
  }
  
  /// Refresh the documents list
  void refreshDocuments() {
    _state?.refreshDocuments();
  }
  
  /// Force UI update
  void forceUIUpdate() {
    _state?.forceUIUpdate();
  }
}

class _DocumentListPanelState extends State<DocumentListPanel> {
  String _query = '';
  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = true;
  String? _error;
  ParsedDocumentsRepository? _repo;
  DocumentListController? _controller;

  @override
  void initState() {
    super.initState();
    _repo = ParsedDocumentsRepository(baseUrl: ApiConfig.baseUrl);
    // Load documents after a short delay to ensure everything is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadDocuments();
      }
    });
  }

  @override
  void dispose() {
    _controller?._detach();
    super.dispose();
  }

  /// Called when the page becomes visible again
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only refresh if repository is already initialized
    if (_repo != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadDocuments();
        }
      });
    }
  }

  /// Attach a controller to this state
  void attachController(DocumentListController controller) {
    _controller = controller;
    controller._attach(this);
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
    final lang = LanguageScope.maybeOf(context)?.language ?? AppLanguage.en;
    final i18n = DocumentsI18n.mapFor(lang);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListHeader(title: i18n['docs.list.title'] ?? 'Document List'),
          SearchField(onChanged: (v) => setState(() => _query = v)),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          
          // Document count and refresh button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_documents.length} document${_documents.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          // List
          Expanded(
            child: Builder(
              builder: (context) {
                if (_isLoading) {
                  return const _LoadingListSkeleton();
                }
                if (_error != null) {
                  return _ErrorCard(error: _error!, i18n: i18n);
                }
                
                final String q = _query.trim().toLowerCase();
                List<Map<String, dynamic>> list = _documents;
                if (q.isNotEmpty) {
                  list = list.where((e) {
                    final name = (e['file_name'] ?? '').toString().toLowerCase();
                    return name.contains(q);
                  }).toList();
                }
                if (list.isEmpty) {
                  return _EmptyStateCard(i18n: i18n);
                }
                return ListView.separated(
                  key: ValueKey('documents_list_${_documents.length}'),
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
                      child: DocumentListItem(
                        title: title,
                        meta: meta,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DocumentViewDetail(
                                title: title,
                                meta: meta,
                                docId: 'server-$id',
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

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
  const _EmptyStateCard({required this.i18n});
  final Map<String, String> i18n;

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
          children: [
            const Icon(Icons.inbox_rounded, color: Color(0xFF64748B)),
            const SizedBox(width: 8),
            Text(i18n['docs.empty'] ?? 'No documents uploaded yet', style: const TextStyle(color: Color(0xFF334155))),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error, required this.i18n});
  final String error;
  final Map<String, String> i18n;

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
                '${i18n['docs.error.load'] ?? 'Failed to load documents'}: $error',
                style: const TextStyle(color: Color(0xFF991B1B)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

