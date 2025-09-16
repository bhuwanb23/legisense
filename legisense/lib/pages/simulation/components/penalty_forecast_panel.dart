import 'package:flutter/material.dart';

class PenaltyForecastPanel extends StatelessWidget {
  final String documentTitle;
  final Map<String, dynamic> parameters;
  final Map<String, dynamic>? simulationData;

  const PenaltyForecastPanel({
    super.key,
    required this.documentTitle,
    required this.parameters,
    this.simulationData,
  });

  @override
  Widget build(BuildContext context) {
    final Color headerColor = const Color(0xFF111827);
    final List<Map<String, dynamic>> rows = _getPenaltyForecastData();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Penalty & Liability Forecast',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: headerColor,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),

        // Simple table
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                _tableHeader(context),
                const Divider(height: 1),
                ...rows.map((r) => _tableRow(context, r)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Simple bar chart (placeholder)
        SizedBox(
          height: 120,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double labelSpace = 18; // space for label text below bars
              final double gapSpace = 6; // space between bar and label
              final double maxBarHeight = (constraints.maxHeight - labelSpace - gapSpace).clamp(0.0, constraints.maxHeight);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: rows.map((r) {
                  final double total = (r['total'] as num).toDouble();
                  final double h = (total / 22000.0) * maxBarHeight;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: h,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          SizedBox(height: gapSpace),
                          SizedBox(
                            height: labelSpace,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                (r['month'] as String).replaceAll('Month ', 'M'),
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),

        const SizedBox(height: 8),
        Text(
          'By Month 6, total owed ≈ ₹20,800 (base + fees + penalties).',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF374151)),
        ),
      ],
    );
  }

  Widget _tableHeader(BuildContext context) {
    TextStyle? style = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF111827),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          _cell('Month', flex: 3, style: style),
          _cell('Base', flex: 2, style: style, align: TextAlign.right),
          _cell('Fees', flex: 2, style: style, align: TextAlign.right),
          _cell('Penalties', flex: 3, style: style, align: TextAlign.right),
          _cell('Total', flex: 2, style: style, align: TextAlign.right),
        ],
      ),
    );
  }

  Widget _tableRow(BuildContext context, Map<String, dynamic> r) {
    TextStyle? style = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          _cell(r['month'] as String, flex: 3, style: style),
          _cell('₹${r['base']}', flex: 2, style: style, align: TextAlign.right),
          _cell('₹${r['fees']}', flex: 2, style: style, align: TextAlign.right),
          _cell('₹${r['penalties']}', flex: 3, style: style, align: TextAlign.right),
          _cell('₹${r['total']}', flex: 2, style: style, align: TextAlign.right),
        ],
      ),
    );
  }

  Widget _cell(String text, {int flex = 1, TextStyle? style, TextAlign? align}) {
    return Expanded(
      flex: flex,
      child: Text(text, style: style, textAlign: align),
    );
  }

  List<Map<String, dynamic>> _getPenaltyForecastData() {
    // Use real simulation data if available, otherwise fall back to mock data
    if (simulationData != null) {
      final penaltyData = simulationData!['penalty_forecast'] as List<dynamic>?;
      if (penaltyData != null && penaltyData.isNotEmpty) {
        return penaltyData.map((item) {
          final data = item as Map<String, dynamic>;
          return {
            'month': data['label'] as String? ?? 'Month',
            'base': (data['base_amount'] as num?)?.toInt() ?? 0,
            'fees': (data['fees_amount'] as num?)?.toInt() ?? 0,
            'penalties': (data['penalties_amount'] as num?)?.toInt() ?? 0,
            'total': (data['total_amount'] as num?)?.toInt() ?? 0,
          };
        }).toList();
      }
    }
    
    // Fall back to mock data
    return [
      {'month': 'Month 1', 'base': 12000, 'fees': 500, 'penalties': 0, 'total': 12500},
      {'month': 'Month 3', 'base': 12000, 'fees': 1500, 'penalties': 2500, 'total': 16000},
      {'month': 'Month 6', 'base': 12000, 'fees': 2600, 'penalties': 6200, 'total': 20800},
    ];
  }
}


