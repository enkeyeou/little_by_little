import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class HomeProgressCard extends StatelessWidget {
  final Widget child;

  const HomeProgressCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
