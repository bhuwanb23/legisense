import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class WhatIfPanel extends StatelessWidget {
  const WhatIfPanel({super.key, required this.onRun});
  final ValueChanged<Map<String, dynamic>> onRun;

  @override
  Widget build(BuildContext context) {
    final missedPayment = ValueNotifier<bool>(false);
    final earlyExit = ValueNotifier<bool>(false);
    final clauseIgnored = ValueNotifier<bool>(false);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What‑If Panel', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _switch('Missed payment', missedPayment),
          _switch('Early exit', earlyExit),
          _switch('Clause ignored', clauseIgnored),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => onRun({
                'missedPayment': missedPayment.value,
                'earlyExit': earlyExit.value,
                'clauseIgnored': clauseIgnored.value,
              }),
              child: const Text('Run Simulation'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _switch(String label, ValueNotifier<bool> v) {
    return ValueListenableBuilder<bool>(
      valueListenable: v,
      builder: (_, value, __) => SwitchListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        value: value,
        onChanged: (nv) => v.value = nv,
      ),
    );
  }
}


