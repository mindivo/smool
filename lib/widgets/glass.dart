import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lgw;

import '../theme/app_theme.dart';

const _defaultGlassSettings = lgw.LiquidGlassSettings(
  thickness: 14,
  glassColor: SmoolColors.glassTint,
  lightAngle: 0.8,
  lightIntensity: 1.0,
  ambientStrength: 0.55,
  chromaticAberration: 1.5,
  blur: 0.0, // No blur effect as requested
);

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double thickness;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24,
    this.thickness = 14,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = lgw.GlassCard(
      padding: padding,
      useOwnLayer: true,
      shape: lgw.LiquidRoundedSuperellipse(borderRadius: borderRadius),
      settings: _defaultGlassSettings.copyWith(thickness: thickness),
      child: child,
    );

    if (onTap == null) return card;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}

class GlassPill extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? tint;

  const GlassPill({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    this.onTap,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final pill = lgw.GlassCard(
      padding: padding,
      useOwnLayer: true,
      shape: const lgw.LiquidRoundedSuperellipse(borderRadius: 40),
      settings: _defaultGlassSettings.copyWith(
        thickness: 19,
        glassColor: tint ?? SmoolColors.glassTint,
      ),
      child: child,
    );
    if (onTap == null) return pill;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: pill,
    );
  }
}

class GlassCircleIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback? onTap;

  const GlassCircleIcon({
    super.key,
    required this.icon,
    this.size = 44,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final widget = SizedBox(
      width: size,
      height: size,
      child: lgw.GlassCard(
        padding: EdgeInsets.zero,
        useOwnLayer: true,
        shape: const lgw.LiquidOval(),
        settings: _defaultGlassSettings.copyWith(thickness: 27),
        child: Center(
          child: Icon(icon, size: size * 0.45, color: SmoolColors.stone),
        ),
      ),
    );
    if (onTap == null) return widget;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: widget,
    );
  }
}
