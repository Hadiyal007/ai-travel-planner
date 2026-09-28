import 'package:flutter/material.dart';
import '../app/theme.dart';

/// The app's one recurring visual mark — a passport-stamp ring around a
/// compass icon — used on the splash screen and reused on login/signup
/// so the brand reads as one consistent thing.
///
/// Colors are nullable and resolved inside [build] rather than given as
/// const default values, so this widget never depends on AppTheme's
/// members being usable in a constant expression.
class BrandMark extends StatelessWidget {
  final double size;
  final Color? ringColor;
  final Color? iconColor;

  const BrandMark({
    super.key,
    this.size = 72,
    this.ringColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor ?? AppTheme.marigold, width: 2.5),
      ),
      child: Icon(
        Icons.explore_outlined,
        size: size * 0.46,
        color: iconColor ?? AppTheme.indigoNight,
      ),
    );
  }
}