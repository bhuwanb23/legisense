import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                    width: 40,
                    height: 40,
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
                
                const SizedBox(width: 16),
                
                // Document Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Document Analysis',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        documentTitle,
                        style: GoogleFonts.inter(
                          fontSize: 20,
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
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
                      'Switch Document:',
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
            
            const SizedBox(height: 16),
            
            // Status Indicators
            LayoutBuilder(
              builder: (context, constraints) {
                // If screen is very narrow, stack indicators vertically
                if (constraints.maxWidth < 300) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusIndicator(
                        icon: FontAwesomeIcons.circleCheck,
                        label: 'Analysis Complete',
                        color: const Color(0xFF10B981),
                      ),
                      const SizedBox(height: 8),
                      _buildStatusIndicator(
                        icon: FontAwesomeIcons.play,
                        label: 'Simulation Ready',
                        color: const Color(0xFF2563EB),
                      ),
                      const SizedBox(height: 8),
                      _buildStatusIndicator(
                        icon: FontAwesomeIcons.robot,
                        label: 'AI Enhanced',
                        color: const Color(0xFF8B5CF6),
                      ),
                    ],
                  );
                }
                // Otherwise, use horizontal layout with flexible children
                return Row(
                  children: [
                    Expanded(
                      child: _buildStatusIndicator(
                        icon: FontAwesomeIcons.circleCheck,
                        label: 'Analysis Complete',
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatusIndicator(
                        icon: FontAwesomeIcons.play,
                        label: 'Simulation Ready',
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatusIndicator(
                        icon: FontAwesomeIcons.robot,
                        label: 'AI Enhanced',
                        color: const Color(0xFF8B5CF6),
                      ),
                    ),
                  ],
                );
              },
            ),
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

  Widget _buildStatusIndicator({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 12,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF374151),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
