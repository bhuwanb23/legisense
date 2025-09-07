import 'package:flutter/material.dart';
import 'document_view_detail.dart';
import 'components/components.dart';
import '../../api/parsed_documents_repository.dart';

class DocumentListPanel extends StatelessWidget {
  const DocumentListPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = ParsedDocumentsRepository(baseUrl: const String.fromEnvironment('LEGISENSE_API_BASE', defaultValue: 'http://10.0.2.2:8000'));
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ListHeader(title: 'Document List'),
          const SearchField(),

          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          // List
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: repo.fetchDocuments(),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Failed to load documents: ${snapshot.error}'));
                }
                final list = snapshot.data ?? const [];
                if (list.isEmpty) {
                  return const Center(child: Text('No documents uploaded yet'));
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
                    return DocumentListItem(
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

