import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AudioVisualizer extends StatelessWidget {
  final List<double> barLevels;
  final double maxHeight;

  const AudioVisualizer({
    super.key,
    required this.barLevels,
    this.maxHeight = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(barLevels.length, (index) {
        final height = (barLevels[index] * maxHeight).clamp(4.0, maxHeight);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          width: 5.5,
          height: height,
          decoration: BoxDecoration(
            color: AppTheme.textPrimary,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
