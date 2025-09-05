import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DocumentListItem extends StatelessWidget {
  const DocumentListItem({super.key, required this.title, required this.meta, required this.onTap});

  final String title;
  final String meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final _FilePresentation pres = _filePresentationFromTitle(title);

    return InkWell(
      onTap: onTap,
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
                          title,
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
                    meta,
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),

            // Trailing menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF9CA3AF)),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'open', child: Text('Open')),
                PopupMenuItem(value: 'download', child: Text('Download')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              onSelected: (v) {},
            ),
          ],
        ),
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


