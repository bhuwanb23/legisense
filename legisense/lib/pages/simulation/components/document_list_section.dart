import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../documents/data/sample_documents.dart';

class DocumentListSection extends StatelessWidget {
  final Function(String documentId, String documentTitle)? onDocumentTap;
  
  const DocumentListSection({
    super.key,
    this.onDocumentTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM, vertical: AppTheme.spacingS),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
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
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingS),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.folderOpen,
                    size: 16,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text(
                    'Available Documents',
                    style: AppTheme.heading4.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingS),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingM,
                    vertical: AppTheme.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    border: Border.all(
                      color: AppTheme.successGreen.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${kSampleDocuments.length} Files',
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.successGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          // Document list with natural height - no internal scrolling
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: kSampleDocuments.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
            itemBuilder: (context, index) {
              final document = kSampleDocuments[index];
              final pres = _filePresentationFromTitle(document.title);
              
              return InkWell(
                onTap: () => onDocumentTap?.call(document.id, document.title),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      // Leading file badge
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: pres.bg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(pres.icon, size: 18, color: pres.fg),
                      ),
                      const SizedBox(width: 12),

                      // Title + meta
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    document.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF111827),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Extension chip
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: pres.chipBg,
                                    borderRadius: BorderRadius.circular(9999),
                                    border: Border.all(color: pres.chipBorder),
                                  ),
                                  child: Text(
                                    pres.ext.toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: pres.chipFg,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              document.meta,
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ),

                      // Trailing arrow
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FilePresentation {
  const _FilePresentation({required this.icon, required this.bg, required this.fg, required this.ext, required this.chipBg, required this.chipFg, required this.chipBorder});
  final IconData icon;
  final Color bg;
  final Color fg;
  final String ext;
  final Color chipBg;
  final Color chipFg;
  final Color chipBorder;
}

_FilePresentation _filePresentationFromTitle(String title) {
  final lower = title.toLowerCase();
  String ext = '';
  final dot = lower.lastIndexOf('.');
  if (dot != -1 && dot < lower.length - 1) {
    ext = lower.substring(dot + 1);
  }
  switch (ext) {
    case 'pdf':
      return const _FilePresentation(
        icon: Icons.picture_as_pdf,
        bg: Color(0xFFFEE2E2),
        fg: Color(0xFFDC2626),
        ext: 'pdf',
        chipBg: Color(0xFFFFF1F2),
        chipFg: Color(0xFFB91C1C),
        chipBorder: Color(0xFFFECACA),
      );
    case 'doc':
    case 'docx':
      return const _FilePresentation(
        icon: Icons.description,
        bg: Color(0xFFDBEAFE),
        fg: Color(0xFF2563EB),
        ext: 'docx',
        chipBg: Color(0xFFEFF6FF),
        chipFg: Color(0xFF1D4ED8),
        chipBorder: Color(0xFFBFDBFE),
      );
    case 'txt':
      return const _FilePresentation(
        icon: Icons.notes,
        bg: Color(0xFFF3F4F6),
        fg: Color(0xFF6B7280),
        ext: 'txt',
        chipBg: Color(0xFFF9FAFB),
        chipFg: Color(0xFF4B5563),
        chipBorder: Color(0xFFE5E7EB),
      );
    default:
      return const _FilePresentation(
        icon: Icons.insert_drive_file,
        bg: Color(0xFFEFF6FF),
        fg: Color(0xFF2563EB),
        ext: 'file',
        chipBg: Color(0xFFF3F4F6),
        chipFg: Color(0xFF374151),
        chipBorder: Color(0xFFE5E7EB),
      );
  }
}
