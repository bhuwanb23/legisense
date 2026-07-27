import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../profile/language/language_scope.dart';
import '../language/strings.dart';

class LegendBar extends StatelessWidget {
  const LegendBar({
    super.key,
    this.showObligation = true,
    this.showWarning = true,
    this.showPenalty = true,
    this.showSuccess = false,
    this.showInfo = false,
    this.customItems = const [],
  });

  final bool showObligation;
  final bool showWarning;
  final bool showPenalty;
  final bool showSuccess;
  final bool showInfo;
  final List<LegendItem> customItems;

  @override
  Widget build(BuildContext context) {
    final scope = LanguageScope.maybeOf(context);
    final i18n = SimulationI18n.mapFor(scope?.language ?? AppLanguage.en);
    final items = <LegendItem>[];
    
    if (showObligation) {
      items.add(const LegendItem(
        label: 'legend.obligation',
        color: Color(0xFF2563EB),
        icon: Icons.check_circle_outline,
      ));
    }
    
    if (showWarning) {
      items.add(const LegendItem(
        label: 'legend.warning',
        color: Color(0xFFF59E0B),
        icon: Icons.warning_amber_outlined,
      ));
    }
    
    if (showPenalty) {
      items.add(const LegendItem(
        label: 'legend.penalty',
        color: Color(0xFFDC2626),
        icon: Icons.error_outline,
      ));
    }
    
    if (showSuccess) {
      items.add(const LegendItem(
        label: 'legend.success',
        color: Color(0xFF10B981),
        icon: Icons.check_circle,
      ));
    }
    
    if (showInfo) {
      items.add(const LegendItem(
        label: 'legend.info',
        color: Color(0xFF6B7280),
        icon: Icons.info_outline,
      ));
    }
    
    items.addAll(customItems);

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            i18n['legend.title'] ?? 'Legend',
            style: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: items.map((item) => _LegendDot(item: item, i18n: i18n)).toList(),
          ),
        ],
      ),
    );
  }
}

class LegendItem {
  const LegendItem({
    required this.label,
    required this.color,
    this.icon,
    this.description,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final String? description;
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.item, required this.i18n});
  final LegendItem item;
  final Map<String, String> i18n;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: item.description ?? (i18n[item.label] ?? item.label),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: item.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: item.color.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: item.icon != null
                ? Icon(
                    item.icon,
                    size: 8,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(width: 6),
          Text(
            i18n[item.label] ?? item.label,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}


