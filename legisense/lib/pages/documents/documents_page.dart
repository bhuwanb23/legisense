import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'document_list.dart';
import '../../components/main_header.dart';
import '../../theme/app_theme.dart';
// Only list on this page; detail is a separate route

class DocumentsPage extends StatelessWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            // Decorative top gradient
            Container(
              height: 140,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFEFF6FF), // blue-50
                    Color(0xFFF5F3FF), // purple-50
                  ],
                ),
              ),
            ),

            // Content
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Global Main Header
                const MainHeader(title: 'Documents'),

                // Subtitle row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                  child: Row(
                    children: [
                      const Icon(FontAwesomeIcons.folderOpen, size: 14, color: AppTheme.textMuted),
                      const SizedBox(width: AppTheme.spacingS),
                      Text(
                        'Browse and manage your files',
                        style: AppTheme.caption,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.spacingM),

                // List-only layout
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingS),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double width = constraints.maxWidth;
                        final bool isWide = width >= 600;

                        final Widget list = const DocumentListPanel();

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Flexible(flex: 100, child: list),
                            ],
                          );
                        }

                        return list;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
