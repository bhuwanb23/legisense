import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import 'risk_style.dart';

class RiskGauge extends StatefulWidget {
  const RiskGauge({
    super.key,
    required this.score,
    this.size = 168,
    this.showLabel = true,
  });

  final int score;
  final double size;
  final bool showLabel;

  @override
  State<RiskGauge> createState() => _RiskGaugeState();
}

class _RiskGaugeState extends State<RiskGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = RiskStyle.scoreColor(widget.score);
    final band = RiskStyle.bandForScore(widget.score);

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final value = (widget.score.clamp(0, 100) / 100) * _anim.value;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  startDegreeOffset: -90,
                  sectionsSpace: 0,
                  centerSpaceRadius: widget.size * 0.32,
                  sections: [
                    PieChartSectionData(
                      value: (value * 100).clamp(0.001, 100),
                      color: color,
                      radius: widget.size * 0.12,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      value: ((1 - value) * 100).clamp(0.001, 100),
                      color: AppColors.progressIdle,
                      radius: widget.size * 0.12,
                      showTitle: false,
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'RISK SCORE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(widget.score * _anim.value).round()}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: widget.size * 0.22,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  Text(
                    '/ 100',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  if (widget.showLabel) ...[
                    const SizedBox(height: 6),
                    RiskChip(level: band),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
