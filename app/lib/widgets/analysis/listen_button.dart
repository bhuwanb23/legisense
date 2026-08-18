import 'package:flutter/material.dart';

import '../../services/tts_service.dart';
import '../../theme/app_theme.dart';

/// Speaker toggle that reads [text] aloud via [TtsService].
/// Turns into a stop button while that exact text is being spoken.
class ListenButton extends StatelessWidget {
  const ListenButton({
    super.key,
    required this.text,
    this.iconSize = 18,
    this.tooltip = 'Read aloud',
  });

  final String text;
  final double iconSize;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: TtsService.instance.speakingText,
      builder: (context, speaking, _) {
        final active = speaking != null && speaking == text;
        return IconButton(
          onPressed: () => TtsService.instance.toggle(text),
          tooltip: active ? 'Stop reading' : tooltip,
          visualDensity: VisualDensity.compact,
          icon: Icon(
            active ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
            size: iconSize,
            color: active ? AppColors.primaryNavy : AppColors.inkSoft,
          ),
        );
      },
    );
  }
}
