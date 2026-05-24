// ignore_for_file: require_trailing_commas

import 'package:flutter/material.dart';
import 'package:refsure/design_system/theme/app_colors.dart';

class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  const SectionCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface, borderRadius: BorderRadius.circular(8),
    child: InkWell(
      borderRadius: BorderRadius.circular(8), onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border)),
        child: child)));
}
