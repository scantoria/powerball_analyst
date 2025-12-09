import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Widget for displaying a lottery ball number
/// Supports white balls and powerball with appropriate styling
class NumberBall extends StatelessWidget {
  final int number;
  final bool isPowerball;
  final double size;
  final bool isSelected;

  const NumberBall({
    super.key,
    required this.number,
    this.isPowerball = false,
    this.size = 48,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final ballColor = isPowerball ? AppColors.powerballFill : AppColors.whiteBallFill;
    final textColor = isPowerball ? AppColors.powerballText : AppColors.textPrimary;
    final borderColor = isPowerball ? AppColors.powerballFill : AppColors.whiteBallBorder;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ballColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.accentOrange : borderColor,
          width: isSelected ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          number.toString(),
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

/// Row of number balls
class NumberBallRow extends StatelessWidget {
  final List<int> numbers;
  final int? powerball;
  final double ballSize;
  final double spacing;

  const NumberBallRow({
    super.key,
    required this.numbers,
    this.powerball,
    this.ballSize = 48,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        ...numbers.map((n) => NumberBall(number: n, size: ballSize)),
        if (powerball != null) ...[
          SizedBox(width: spacing),
          NumberBall(
            number: powerball!,
            isPowerball: true,
            size: ballSize,
          ),
        ],
      ],
    );
  }
}
