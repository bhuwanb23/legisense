import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class UploadZone extends StatefulWidget {
  const UploadZone({super.key});

  @override
  State<UploadZone> createState() => _UploadZoneState();
}

class _UploadZoneState extends State<UploadZone> {
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isDragOver 
                ? const Color(0xFF3B82F6) 
                : const Color(0xFF93C5FD),
            width: 2,
            style: BorderStyle.solid,
          ),
          boxShadow: _isDragOver
              ? [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          children: [
            // Upload Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                FontAwesomeIcons.cloudArrowUp,
                color: Colors.white,
                size: 24,
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.8, 0.8),
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: 800.ms, delay: 200.ms),
            
            const SizedBox(height: 16),
            
            // Title and Description
            Text(
              'Upload Your Contract',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            )
                .animate()
                .slideY(
                  begin: 0.3,
                  duration: 600.ms,
                  curve: Curves.easeOut,
                )
                .fadeIn(duration: 800.ms, delay: 400.ms),
            
            const SizedBox(height: 8),
            
            Text(
              'Drag and drop files here or click to browse',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6B7280),
              ),
            )
                .animate()
                .slideY(
                  begin: 0.3,
                  duration: 600.ms,
                  curve: Curves.easeOut,
                )
                .fadeIn(duration: 800.ms, delay: 600.ms),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Column(
              children: [
                // Upload Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Implement file upload
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          FontAwesomeIcons.upload,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Upload Contract',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 800.ms, delay: 800.ms),
                
                const SizedBox(height: 12),
                
                // Sample Document Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: Implement sample document
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF374151),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          FontAwesomeIcons.fileLines,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Use Sample Document',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 800.ms, delay: 1000.ms),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
