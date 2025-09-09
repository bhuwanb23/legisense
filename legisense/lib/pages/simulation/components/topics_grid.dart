import 'package:flutter/material.dart';
import 'topic_chip.dart';

class TopicsGrid extends StatelessWidget {
  const TopicsGrid({super.key, required this.onSelect});
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String)>[
      (Icons.schedule, 'Obligation Timeline', 'timeline'),
      (Icons.help_outline, 'What‑If Scenarios', 'whatif'),
      (Icons.report, 'Penalty & Liability', 'penalty'),
      (Icons.logout, 'Termination / Exit', 'exit'),
      (Icons.compare, 'Comparative Scenario', 'compare'),
      (Icons.gavel, 'Jurisdiction‑Specific', 'jurisdiction'),
      (Icons.trending_up, 'Long‑Term Forecast', 'forecast'),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final it in items)
          TopicChip(
            icon: it.$1,
            label: it.$2,
            onTap: () => onSelect(it.$3),
          ),
      ],
    );
  }
}


