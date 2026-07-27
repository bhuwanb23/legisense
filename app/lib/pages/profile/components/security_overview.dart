import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class SecurityOverview extends StatelessWidget {
  const SecurityOverview({super.key, this.devices = 0, this.sessions = 1, this.is2FAEnabled = false});

  final int devices;
  final int sessions;
  final bool is2FAEnabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.security, color: AppTheme.successGreen, size: 18),
                SizedBox(width: 8),
                Text('Security Overview', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _SecurityChip(icon: Icons.devices, label: '$devices devices'),
                const SizedBox(width: 8),
                _SecurityChip(icon: Icons.access_time, label: '$sessions active sessions'),
                const SizedBox(width: 8),
                _SecurityChip(icon: is2FAEnabled ? Icons.verified_user : Icons.error_outline, label: is2FAEnabled ? '2FA enabled' : '2FA disabled', color: is2FAEnabled ? AppTheme.successGreen : AppTheme.warningOrange),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityChip extends StatelessWidget {
  const _SecurityChip({required this.icon, required this.label, this.color = AppTheme.primaryBlue});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}


