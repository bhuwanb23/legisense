import 'package:flutter/material.dart';

class ContextualTooltip extends StatelessWidget {
  const ContextualTooltip({super.key, required this.child, required this.text});
  final Widget child;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: text,
      triggerMode: TooltipTriggerMode.tap,
      child: child,
    );
  }
}


