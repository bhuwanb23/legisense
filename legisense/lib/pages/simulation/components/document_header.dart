import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'styles.dart';
import '../../profile/language/language_scope.dart';
import '../language/strings.dart';

class DocumentHeader extends StatelessWidget {
  final String documentTitle;
  final String documentVersion;
  final VoidCallback? onBackPressed;
  final VoidCallback? onDocumentSwitch;
  final List<String>? availableDocuments;
  
  const DocumentHeader({
    super.key,
    required this.documentTitle,
    this.documentVersion = 'V2.1',
    this.onBackPressed,
    this.onDocumentSwitch,
    this.availableDocuments,
  });

  String _getValidDropdownValue() {
    if (availableDocuments == null || availableDocuments!.isEmpty) {
      return documentTitle;
    }
    final uniqueDocuments = availableDocuments!.toSet().toList();
    return uniqueDocuments.contains(documentTitle) ? documentTitle : uniqueDocuments.first;
  }

  @override
  Widget build(BuildContext context) {
    final scope = LanguageScope.maybeOf(context);
    final i18n = SimulationI18n.mapFor(scope?.language ?? AppLanguage.en);
    return Container(
      decoration: SimStyles.sectionDecoration(),
      child: Padding(
        padding: SimStyles.sectionPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Back Button
                GestureDetector(
                  onTap: onBackPressed ?? () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      FontAwesomeIcons.arrowLeft,
                      color: Color(0xFF374151),
                      size: 16,
                    ),
                  ),
                ),
                
                const SizedBox(width: 14),
                
                // Document Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i18n['document.header.subtitle'] ?? 'Document Analysis',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        documentTitle,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F2937),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Document Version Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    documentVersion,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Document Switch Dropdown (if available)
            if (availableDocuments != null && availableDocuments!.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    FontAwesomeIcons.fileLines,
                    size: 16,
                    color: const Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      i18n['document.switch'] ?? 'Switch Document:',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF374151),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _getValidDropdownValue(),
                          isExpanded: true,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF374151),
                          ),
                          items: (availableDocuments ?? []).toSet().map((doc) {
                            return DropdownMenuItem<String>(
                              value: doc,
                              child: Text(
                                doc,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null && value != documentTitle) {
                              onDocumentSwitch?.call();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    )
        .animate()
        .slideY(
          begin: -0.3,
          duration: 600.ms,
          curve: Curves.easeOut,
        )
        .fadeIn(duration: 600.ms);
  }

}
