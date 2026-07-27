import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/bottom_nav_bar.dart';
import '../../main.dart';
import '../../theme/app_theme.dart';
import '../profile/language/language_scope.dart';
import 'language/strings.dart';

/// Document detail shell — content returns when the new API is connected.
class DocumentViewDetail extends StatefulWidget {
  const DocumentViewDetail({
    super.key,
    required this.title,
    required this.meta,
    this.docId,
  });

  final String title;
  final String meta;
  final String? docId;

  @override
  State<DocumentViewDetail> createState() => _DocumentViewDetailState();
}

class _DocumentViewDetailState extends State<DocumentViewDetail> {
  static const int _currentPageIndex = 1;

  void _onPageChanged(int index) {
    if (index == _currentPageIndex) return;
    navigateToPage(index);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final i18n = DocumentsI18n.mapFor(
      LanguageScope.maybeOf(context)?.language ?? AppLanguage.en,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          widget.meta,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 48,
                        color: AppTheme.textSecondary.withValues(alpha: 0.45),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        i18n['docs.detail.empty'] ?? 'Document preview unavailable',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        i18n['docs.detail.emptyHint'] ??
                            'Viewer and analysis will reconnect with the new backend.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            BottomNavBar(
              currentIndex: _currentPageIndex,
              onTap: _onPageChanged,
            ),
          ],
        ),
      ),
    );
  }
}
