import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ViewerToolbar extends StatelessWidget {
  const ViewerToolbar({super.key, this.onFit, this.onZoomIn, this.onZoomOut});

  final VoidCallback? onFit;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Document Viewer',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
              ],
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: onFit,
                  icon: const Icon(Icons.zoom_out_map, size: 18, color: Color(0xFF6B7280)),
                  tooltip: 'Fit to width',
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onZoomIn,
                  icon: const Icon(Icons.zoom_in, size: 18, color: Color(0xFF6B7280)),
                  tooltip: 'Zoom in',
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onZoomOut,
                  icon: const Icon(Icons.zoom_out, size: 18, color: Color(0xFF6B7280)),
                  tooltip: 'Zoom out',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


