import 'package:flutter/material.dart';

class SkeletonLine extends StatefulWidget {
  const SkeletonLine({super.key, this.width, this.height = 12, this.radius = 8});

  final double? width;
  final double height;
  final double radius;

  @override
  State<SkeletonLine> createState() => _SkeletonLineState();
}

class _SkeletonLineState extends State<SkeletonLine> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              colors: [
                Colors.grey.shade200,
                Colors.grey.shade100,
                Colors.grey.shade200,
              ],
              stops: [0.1, 0.5, 0.9],
              begin: Alignment(-1 + 2 * _controller.value, 0),
              end: const Alignment(1, 0),
            ),
          ),
        );
      },
    );
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.size = 40, this.radius = 8});

  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return SkeletonLine(width: size, height: size, radius: radius);
  }
}


