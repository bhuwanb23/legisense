import 'package:flutter/material.dart';

class JurisdictionNotice extends StatelessWidget {
  final String jurisdiction;
  final String message;

  const JurisdictionNotice({
    super.key,
    required this.jurisdiction,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.gavel, color: Color(0xFF10B981)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jurisdiction Adjustment · $jurisdiction',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF065F46),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF065F46)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


