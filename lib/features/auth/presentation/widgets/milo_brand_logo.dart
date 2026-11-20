import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class MiloBrandLogo extends StatelessWidget {
  final double height;

  const MiloBrandLogo({
    super.key,
    this.height = 76,
  });

  /// Converts dark-grey box pixels (R < 35) to transparent (Alpha = 0)
  /// while keeping the burgundy MILO DRIVE logo pixels 100% crisp.
  static const ColorFilter _stripDarkBoxFilter = ColorFilter.matrix([
    1.1, 0.0, 0.0, 0.0, 0.0,
    0.0, 1.05, 0.0, 0.0, 0.0,
    0.0, 0.0, 1.1, 0.0, 0.0,
    6.0, 0.0, 0.0, 0.0, -210.0,
  ]);

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: _stripDarkBoxFilter,
      child: Image.asset(
        'assets/images/milo_logo.png',
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.miloCrimson,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.electric_car_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}