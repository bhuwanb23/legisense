import 'package:flutter/material.dart';

class LongTermForecastChart extends StatelessWidget {
  final String documentTitle;
  final Map<String, dynamic> parameters;
  final Map<String, dynamic>? simulationData;

  const LongTermForecastChart({
    super.key,
    required this.documentTitle,
    required this.parameters,
    this.simulationData,
  });

  @override
  Widget build(BuildContext context) {
    // Placeholder dataset: cumulative costs over years
    final List<_Point> data = const [
      _Point('Year 1', 40000),
      _Point('Year 2', 90000),
      _Point('Year 3', 120000),
    ];

    double maxVal = data.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Long-Term Forecast',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF111827),
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          ),
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double labelSpace = 18; // reserved for label
              final double gapSpace = 6; // bar-to-label gap
              final double maxBarHeight = (constraints.maxHeight - labelSpace - gapSpace).clamp(0.0, constraints.maxHeight);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final p in data) ...[
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: (p.value / (maxVal == 0 ? 1 : maxVal)) * maxBarHeight,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                                  const Color(0xFF2563EB).withValues(alpha: 0.25),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          SizedBox(height: gapSpace),
                          SizedBox(
                            height: labelSpace,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(p.label, style: Theme.of(context).textTheme.labelSmall),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'If auto-renew isn\'t canceled, projected extra over 3 years ≈ ₹1.2 lakh.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF374151)),
        ),
      ],
    );
  }
}

class _Point {
  final String label;
  final int value;
  const _Point(this.label, this.value);
}


