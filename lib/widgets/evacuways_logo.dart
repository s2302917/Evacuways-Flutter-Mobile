import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class EvacuWaysLogo extends StatelessWidget {
  final double fontSize;
  final double iconSize;
  const EvacuWaysLogo({super.key, this.fontSize = 28, this.iconSize = 36});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.shield, color: Colors.white, size: iconSize * 0.65),
        ),
        const SizedBox(width: 10),
        Text(
          'EvacuWays',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
