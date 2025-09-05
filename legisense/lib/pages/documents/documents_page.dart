import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DocumentsPage extends StatelessWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Documents',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              )
                  .animate()
                  .slideX(
                    begin: -0.3,
                    duration: 600.ms,
                    curve: Curves.easeOut,
                  )
                  .fadeIn(duration: 800.ms),
              
              const SizedBox(height: 8),
              
              Text(
                'Manage and analyze your legal documents',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6B7280),
                ),
              )
                  .animate()
                  .slideX(
                    begin: -0.3,
                    duration: 600.ms,
                    curve: Curves.easeOut,
                  )
                  .fadeIn(duration: 800.ms, delay: 200.ms),
              
              const SizedBox(height: 32),
              
              // Upload Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF2563EB),
                      Color(0xFF3B82F6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // TODO: Implement upload functionality
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          FontAwesomeIcons.upload,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Upload New Document',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 800.ms, delay: 400.ms),
              
              const SizedBox(height: 32),
              
              // Document List
              _buildDocumentItem(
                title: 'Employment Contract - John Doe',
                subtitle: 'PDF • 2.3 MB • Last modified 2 hours ago',
                icon: FontAwesomeIcons.filePdf,
                color: const Color(0xFFDC2626),
                delay: 600,
              ),
              
              const SizedBox(height: 12),
              
              _buildDocumentItem(
                title: 'Rental Agreement - 123 Main St',
                subtitle: 'PDF • 1.8 MB • Last modified 1 day ago',
                icon: FontAwesomeIcons.filePdf,
                color: const Color(0xFFDC2626),
                delay: 800,
              ),
              
              const SizedBox(height: 12),
              
              _buildDocumentItem(
                title: 'Service Terms - ABC Corp',
                subtitle: 'DOCX • 456 KB • Last modified 3 days ago',
                icon: FontAwesomeIcons.fileWord,
                color: const Color(0xFF2563EB),
                delay: 1000,
              ),
              
              const SizedBox(height: 12),
              
              _buildDocumentItem(
                title: 'Privacy Policy Draft',
                subtitle: 'TXT • 234 KB • Last modified 1 week ago',
                icon: FontAwesomeIcons.fileLines,
                color: const Color(0xFF6B7280),
                delay: 1200,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int delay,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          
          PopupMenuButton<String>(
            icon: const Icon(
              FontAwesomeIcons.ellipsisVertical,
              size: 16,
              color: Color(0xFF9CA3AF),
            ),
            onSelected: (value) {
              // TODO: Handle menu actions
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'analyze',
                child: Text('Analyze'),
              ),
              const PopupMenuItem(
                value: 'download',
                child: Text('Download'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .slideX(
          begin: 0.3,
          duration: 600.ms,
          curve: Curves.easeOut,
        )
        .fadeIn(duration: 800.ms, delay: delay.ms);
  }
}
