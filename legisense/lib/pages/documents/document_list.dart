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

class _DocumentListPanelState extends State<DocumentListPanel> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final repo = ParsedDocumentsRepository(baseUrl: ApiConfig.baseUrl);
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

          // List
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: repo.fetchDocuments(),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const _LoadingListSkeleton();
                }
                if (snapshot.hasError) {
                  return _ErrorCard(error: snapshot.error.toString(), i18n: i18n);
                }
                final String q = _query.trim().toLowerCase();
                List<Map<String, dynamic>> list = (snapshot.data ?? const <Map<String, dynamic>>[]);
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

