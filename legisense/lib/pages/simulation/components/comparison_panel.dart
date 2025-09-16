import 'package:flutter/material.dart';
import 'styles.dart';

class ComparisonPanel extends StatelessWidget {
  final String documentTitle;
  final Map<String, dynamic>? simulationData;

  const ComparisonPanel({
    super.key,
    required this.documentTitle,
    this.simulationData,
  });

  @override
  Widget build(BuildContext context) {
    final List<_ExitScenario> scenarios = _getExitScenarios();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Termination / Exit Comparison',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: const Color(0xFF111827),
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final bool vertical = constraints.maxWidth < 700;
            return vertical
                ? Column(
                    children: scenarios.map((s) => _buildScenarioCard(context, s)).toList(),
                  )
                : Row(
                    children: scenarios.map((s) => Expanded(child: _buildScenarioCard(context, s))).toList(),
                  );
          },
        ),
      ],
    );
  }

  Widget _buildScenarioCard(BuildContext context, _ExitScenario scenario) {
    final Color bgColor = _getRiskColor(scenario.risk).withValues(alpha: 0.1);
    final Color borderColor = _getRiskColor(scenario.risk);
    
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(SimStyles.spaceM),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(SimStyles.radiusM),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            scenario.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
          ),
          const SizedBox(height: 6),
          _buildKeyValue('Penalty', scenario.penalty, context),
          _buildKeyValue('Risk Level', scenario.risk, context),
          _buildKeyValue('Benefits Lost', scenario.benefitsLost, context),
        ],
      ),
    );
  }

  Color _getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'low':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Widget _buildKeyValue(String k, String v, BuildContext context) {
    TextStyle? ks = Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280));
    TextStyle? vs = Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(k, style: ks, maxLines: 1, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              v,
              style: vs,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  List<_ExitScenario> _getExitScenarios() {
    // Use real simulation data if available, otherwise fall back to mock data
    if (simulationData != null) {
      final exitData = simulationData!['exit_comparisons'] as List<dynamic>?;
      if (exitData != null && exitData.isNotEmpty) {
        return exitData.map((item) {
          final data = item as Map<String, dynamic>;
          return _ExitScenario(
            label: data['label'] as String? ?? 'Exit Scenario',
            penalty: data['penalty_text'] as String? ?? '₹0',
            risk: data['risk_level'] as String? ?? 'Low',
            benefitsLost: data['benefits_lost'] as String? ?? 'None',
          );
        }).toList();
      }
    }
    
    // Fall back to mock data
    return const [
      _ExitScenario(label: 'Exit at 6 months', penalty: '₹25,000', risk: 'Medium', benefitsLost: 'Partial'),
      _ExitScenario(label: 'Exit at 12 months', penalty: '₹12,000', risk: 'Low', benefitsLost: 'Minimal'),
      _ExitScenario(label: 'Full term', penalty: '₹0', risk: 'Low', benefitsLost: 'None'),
    ];
  }
}

class _ExitScenario {
  final String label;
  final String penalty;
  final String risk;
  final String benefitsLost;
  const _ExitScenario({required this.label, required this.penalty, required this.risk, required this.benefitsLost});
}