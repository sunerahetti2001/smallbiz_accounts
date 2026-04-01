import 'package:flutter/material.dart';
import '../utils/colors.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  final bool hasBottomRadius;

  const GradientBackground({
    super.key,
    required this.child,
    this.hasBottomRadius = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A4D8C),
            Color(0xFF1E3A8A),
            Color(0xFF1E1B4B),
          ],
        ),
        borderRadius: hasBottomRadius
            ? const BorderRadius.only(
          bottomLeft: Radius.circular(48),
          bottomRight: Radius.circular(48),
        )
            : null,
      ),
      child: child,
    );
  }
}