import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'document_list.dart';
import '../../components/main_header.dart';
// Only list on this page; detail is a separate route

class DocumentsPage extends StatelessWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Global Main Header
            const MainHeader(title: 'Documents'),
            
            // List-only layout
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double width = constraints.maxWidth;
                  final bool isWide = width >= 600;

                  if (isWide) {
                    return const Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Flexible(
                          flex: 100,
                          child: DocumentListPanel(),
                        ),
                      ],
                    );
                  }

                  return const DocumentListPanel();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
