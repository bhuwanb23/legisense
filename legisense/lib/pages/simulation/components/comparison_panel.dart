import 'package:flutter/material.dart';

class ComparisonPanel extends StatelessWidget {
  final String documentTitle;

  const ComparisonPanel({
    super.key,
    required this.documentTitle,
  });

  @override
  Widget build(BuildContext context) {
    final List<_ExitScenario> scenarios = const [
      _ExitScenario(label: 'Exit at 6 months', penalty: '₹25,000', risk: 'Medium', benefitsLost: 'Partial'),
      _ExitScenario(label: 'Exit at 12 months', penalty: '₹12,000', risk: 'Low', benefitsLost: 'Minimal'),
      _ExitScenario(label: 'Full term', penalty: '₹0', risk: 'Low', benefitsLost: 'None'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Termination / Exit Comparison',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF111827),
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final bool vertical = constraints.maxWidth < 700;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: scenarios.map((s) {
                final double cardWidth = vertical
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 24) / 3; // 12 spacing * 2 approx
                return SizedBox(
                  width: cardWidth,
                  child: _ScenarioCard(
                    scenario: s,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  final _ExitScenario scenario;

  const _ScenarioCard({
    required this.scenario,
  });

  @override
  Widget build(BuildContext context) {
    Color border = Colors.grey.withValues(alpha: 0.2);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(scenario.label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _row(context, 'Estimated penalty', scenario.penalty),
          _row(context, 'Risk of lawsuit', scenario.risk),
          _row(context, 'Benefits lost', scenario.benefitsLost),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String k, String v) {
    TextStyle? ks = Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280));
    TextStyle? vs = Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(k, style: ks)),
          Text(v, style: vs),
        ],
      ),
    );
  }
}

class _ExitScenario {
  final String label;
  final String penalty;
  final String risk;
  final String benefitsLost;
  const _ExitScenario({required this.label, required this.penalty, required this.risk, required this.benefitsLost});
}


