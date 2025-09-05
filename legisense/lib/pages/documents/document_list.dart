import 'package:flutter/material.dart';
import 'document_view_detail.dart';
import 'components/components.dart';

class DocumentListPanel extends StatelessWidget {
  const DocumentListPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final documents = [
      {'title': 'Employment Contract.pdf', 'meta': '2.3 MB • 2h ago'},
      {'title': 'Service Agreement.docx', 'meta': '456 KB • yesterday'},
      {'title': 'NDA Template.pdf', 'meta': '1.1 MB • 3 days ago'},
      {'title': 'Privacy Policy.txt', 'meta': '234 KB • 1 week ago'},
    ];

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
            child: ListView.separated(
              itemCount: documents.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
              itemBuilder: (context, index) {
                final doc = documents[index];
                return DocumentListItem(
                  title: doc['title']!,
                  meta: doc['meta']!,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DocumentViewDetail(
                          title: doc['title']!,
                          meta: doc['meta']!,
                        ),
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

