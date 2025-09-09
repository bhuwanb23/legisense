import 'package:flutter/material.dart';

class RiskInsightsPanel extends StatelessWidget {
  const RiskInsightsPanel({super.key, required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Insights & Risk Alerts', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ...items.map((e) => _row(e)).toList(),
      ],
    );
  }

  Widget _row(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFEAB308), size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Color(0xFF713F12)))),
        ],
      ),
    );
  }
}


