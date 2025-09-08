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
          _AnimatedToolbar(
            onFit: onFit,
            onZoomIn: onZoomIn,
            onZoomOut: onZoomOut,
          ),
        ],
      ),
    );
  }
}

class _AnimatedToolbar extends StatefulWidget {
  const _AnimatedToolbar({this.onFit, this.onZoomIn, this.onZoomOut});
  final VoidCallback? onFit;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;

  @override
  State<_AnimatedToolbar> createState() => _AnimatedToolbarState();
}

class _AnimatedToolbarState extends State<_AnimatedToolbar> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: _hover ? 0.12 : 0.08), blurRadius: _hover ? 16 : 8, offset: const Offset(0, 2)),
          ],
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            _animIcon(
              icon: Icons.zoom_out_map,
              tooltip: 'Fit to width',
              onTap: widget.onFit,
            ),
            const SizedBox(width: 4),
            _animIcon(
              icon: Icons.zoom_in,
              tooltip: 'Zoom in',
              onTap: widget.onZoomIn,
            ),
            const SizedBox(width: 4),
            _animIcon(
              icon: Icons.zoom_out,
              tooltip: 'Zoom out',
              onTap: widget.onZoomOut,
            ),
          ],
        ),
      ),
    );
  }

  Widget _animIcon({required IconData icon, required String tooltip, VoidCallback? onTap}) {
    return _HoverButton(
      tooltip: tooltip,
      onTap: onTap,
      child: Icon(icon, size: 18, color: const Color(0xFF6B7280)),
    );
  }
}

class _HoverButton extends StatefulWidget {
  const _HoverButton({required this.child, required this.tooltip, this.onTap});
  final Widget child;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _hover ? const Color(0xFFF3F4F6) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 140),
              scale: _hover ? 1.05 : 1.0,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}


